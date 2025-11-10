import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';
import '../services/api.dart';
import '../services/storage_service.dart';
import '../models/stream.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String episodeId;
  final String episodeTitle;
  final int episodeNumber;
  final String? animeId;
  final String? animeTitle;
  final String? animePoster;
  final List<dynamic>? allEpisodes; // List of all episodes for next episode feature
  final Function(String episodeId, String episodeTitle, int episodeNumber)? onNextEpisode;

  const VideoPlayerScreen({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
    required this.episodeNumber,
    this.animeId,
    this.animeTitle,
    this.animePoster,
    this.allEpisodes,
    this.onNextEpisode,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final AnimeApi _api = AnimeApi();
  List<Server> availableServers = [];
  StreamInfo? streamInfo;
  Server? selectedServer;
  String selectedType = 'sub';
  bool isLoadingServers = true;
  bool isLoadingStream = false;
  String? error;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  SubtitleController? _subtitleController;
  
  List<Tracks>? availableSubtitles;
  Tracks? selectedSubtitle;

  @override
  void initState() {
    super.initState();
    log('VideoPlayerScreen initialized with ${widget.allEpisodes?.length ?? 0} episodes');
    _loadServers();
    _setLandscapeMode();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _exitFullscreen();
    super.dispose();
  }

  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    // Dispose old controllers if they exist
    _chewieController?.dispose();
    await _videoPlayerController?.dispose();
    
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoPlayerController!.initialize();
      
      // Create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade300,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load video',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      
      // Setup subtitles if available
      if (streamInfo?.streamingLink?.tracks != null && 
          streamInfo!.streamingLink!.tracks!.isNotEmpty) {
        availableSubtitles = streamInfo!.streamingLink!.tracks;
        
        // Find default subtitle or use first available
        selectedSubtitle = availableSubtitles!.firstWhere(
          (track) => track.defaultId == true,
          orElse: () => availableSubtitles!.first,
        );
        
        if (selectedSubtitle != null && selectedSubtitle!.file != null) {
          _subtitleController = SubtitleController(
            subtitleUrl: selectedSubtitle!.file!,
            subtitleType: SubtitleType.webvtt,
          );
        }
      }
      
      setState(() {});
      
      // Save to watch history
      if (widget.animeId != null && widget.animeTitle != null && widget.animePoster != null) {
        StorageService.addToWatchHistory(
          animeId: widget.animeId!,
          animeTitle: widget.animeTitle!,
          animePoster: widget.animePoster!,
          episodeNumber: widget.episodeNumber,
          episodeId: widget.episodeId,
          episodeTitle: widget.episodeTitle,
        );
      }
    } catch (e) {
      // Show toast instead of error screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load video. Try a different server.'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Change Server',
              onPressed: () {
                // Open server menu if available
                if (availableServers.length > 1) {
                  // The user can tap the server icon in the app bar
                }
              },
            ),
          ),
        );
      }
      setState(() {});
    }
  }

  void _changeSubtitle(Tracks? subtitle) {
    setState(() {
      selectedSubtitle = subtitle;
      if (subtitle != null && subtitle.file != null) {
        _subtitleController = SubtitleController(
          subtitleUrl: subtitle.file!,
          subtitleType: SubtitleType.webvtt,
        );
      } else {
        _subtitleController = null;
      }
    });
  }

  Future<void> _loadServers() async {
    setState(() {
      isLoadingServers = true;
      error = null;
    });

    try {
      final data = await _api.getServers(widget.episodeId);
      final servers = (data['results'] as List<dynamic>?)
          ?.map((e) => Server.fromJson(e))
          .toList() ?? [];

      // Get preferred server
      final preferredServerName = await StorageService.getPreferredServer();

      setState(() {
        availableServers = servers;
        isLoadingServers = false;
        
        // Try to select preferred server, otherwise use first
        if (servers.isNotEmpty) {
          if (preferredServerName != null) {
            final preferred = servers.firstWhere(
              (server) => server.serverName?.toLowerCase() == preferredServerName.toLowerCase(),
              orElse: () => servers.first,
            );
            selectedServer = preferred;
            selectedType = preferred.type!;
          } else {
            selectedServer = servers.first;
            selectedType = servers.first.type!;
          }
          _loadStream();
        }
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoadingServers = false;
      });
    }
  }

  Future<void> _loadStream() async {
    if (selectedServer == null) return;

    setState(() {
      isLoadingStream = true;
      error = null;
    });

    try {
      final data = await _api.getStream(
        widget.episodeId,
        selectedServer!.serverName!.toLowerCase(),
        selectedType,
      );


      setState(() {
        // data['results'] should be a Map<String, dynamic> containing streamingLink and servers arrays
        final results = data['results'];
        if (results is Map<String, dynamic>) {
          log(jsonEncode(results));
          streamInfo = StreamInfo.fromJson(results);
          
          // Initialize video player with the stream URL
          if (streamInfo?.streamingLink?.link?.file != null) {
            _initializeVideoPlayer(streamInfo!.streamingLink!.link!.file!);
          }
        } else {
          throw Exception('Unexpected results format: ${results.runtimeType}');
        }
        isLoadingStream = false;
      });
    } catch (e) {
      log('Stream error: $e');
      setState(() {
        error = e.toString();
        isLoadingStream = false;
      });
    }
  }

  void _changeServer(Server server) {
    setState(() {
      selectedServer = server;
      selectedType = server.type!;
      streamInfo = null;
    });
    // Save preferred server
    if (server.serverName != null) {
      StorageService.savePreferredServer(server.serverName!);
    }
    _loadStream();
  }

  dynamic _getNextEpisode() {
    if (widget.allEpisodes == null || widget.allEpisodes!.isEmpty) {
      return null;
    }

    // Find current episode index
    final currentIndex = widget.allEpisodes!.indexWhere((ep) {
      if (ep is Map<String, dynamic>) {
        return ep['episode_no']?.toString() == widget.episodeNumber.toString();
      }
      return false;
    });

    // Return next episode if exists
    if (currentIndex != -1 && currentIndex < widget.allEpisodes!.length - 1) {
      return widget.allEpisodes![currentIndex + 1];
    }

    return null;
  }

  void _playNextEpisode() {
    final nextEpisode = _getNextEpisode();
    if (nextEpisode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more episodes available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (widget.onNextEpisode != null) {
      final nextEpisodeId = nextEpisode['id']?.toString() ?? '';
      final nextEpisodeTitle = nextEpisode['title']?.toString() ?? 
                               'Episode ${nextEpisode['episode_no']}';
      final nextEpisodeNumber = int.tryParse(nextEpisode['episode_no']?.toString() ?? '0') ?? 0;
      
      widget.onNextEpisode!(nextEpisodeId, nextEpisodeTitle, nextEpisodeNumber);
    } else {
      // Fallback: Navigate with replacement
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            episodeId: nextEpisode['id']?.toString() ?? '',
            episodeTitle: nextEpisode['title']?.toString() ?? 
                         'Episode ${nextEpisode['episode_no']}',
            episodeNumber: int.tryParse(nextEpisode['episode_no']?.toString() ?? '0') ?? 0,
            animeId: widget.animeId,
            animeTitle: widget.animeTitle,
            animePoster: widget.animePoster,
            allEpisodes: widget.allEpisodes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isLoadingServers
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadServers,
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : availableServers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No servers available',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        // Video player with subtitles
                        Center(
                          child: isLoadingStream
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : streamInfo != null && _chewieController != null
                                  ? _buildVideoPlayer()
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Loading video...',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                        ),
                        
                        // Top controls overlay
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                                ),
                              ),
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Episode ${widget.episodeNumber}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              widget.episodeTitle,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Server options menu
                                      if (availableServers.isNotEmpty)
                                        PopupMenuButton<Server>(
                                          icon: const Icon(Icons.dns, color: Colors.white),
                                          tooltip: 'Server Options',
                                          onSelected: _changeServer,
                                          itemBuilder: (context) => [
                                            const PopupMenuItem<Server>(
                                              enabled: false,
                                              child: Text(
                                                'Change Server',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            ...availableServers.map((server) {
                                              return PopupMenuItem<Server>(
                                                value: server,
                                                child: Row(
                                                  children: [
                                                    if (server == selectedServer)
                                                      const Icon(Icons.check, size: 16),
                                                    if (server == selectedServer)
                                                      const SizedBox(width: 8),
                                                    Text(server.serverName!),
                                                    const SizedBox(width: 8),
                                                    Chip(
                                                      label: Text(
                                                        server.type!.toUpperCase(),
                                                        style: const TextStyle(fontSize: 10),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      // Subtitle options menu
                                      if (availableSubtitles != null && availableSubtitles!.isNotEmpty)
                                        PopupMenuButton<Tracks?>(
                                          icon: const Icon(Icons.closed_caption, color: Colors.white),
                                          tooltip: 'Subtitle Options',
                                          onSelected: _changeSubtitle,
                                          itemBuilder: (context) => [
                                            const PopupMenuItem<Tracks?>(
                                              enabled: false,
                                              child: Text(
                                                'Subtitles',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            PopupMenuItem<Tracks?>(
                                              value: null,
                                              child: Row(
                                                children: [
                                                  if (selectedSubtitle == null)
                                                    const Icon(Icons.check, size: 16),
                                                  if (selectedSubtitle == null)
                                                    const SizedBox(width: 8),
                                                  const Text('Off'),
                                                ],
                                              ),
                                            ),
                                            ...availableSubtitles!.map((track) {
                                              return PopupMenuItem<Tracks?>(
                                                value: track,
                                                child: Row(
                                                  children: [
                                                    if (track == selectedSubtitle)
                                                      const Icon(Icons.check, size: 16),
                                                    if (track == selectedSubtitle)
                                                      const SizedBox(width: 8),
                                                    Text(track.label ?? track.kind ?? 'Unknown'),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      // Next Episode button
                                      if (_getNextEpisode() != null)
                                        IconButton(
                                          icon: const Icon(Icons.skip_next, color: Colors.white),
                                          tooltip: 'Next Episode',
                                          onPressed: _playNextEpisode,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Wrap video player with subtitle overlay if subtitles are enabled
    if (_subtitleController != null) {
      return SubtitleWrapper(
        subtitleController: _subtitleController!,
        videoPlayerController: _videoPlayerController!,
        subtitleStyle: const SubtitleStyle(
          fontSize: 16,
          textColor: Colors.white,
          hasBorder: true,
          position: SubtitlePosition(bottom: 20),
        ),
        videoChild: Chewie(controller: _chewieController!),
      );
    }

    // Return video player without subtitles
    return Chewie(controller: _chewieController!);
  }
}
