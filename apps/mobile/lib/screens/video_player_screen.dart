import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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

  const VideoPlayerScreen({
    super.key,
    required this.episodeId,
    required this.episodeTitle,
    required this.episodeNumber,
    this.animeId,
    this.animeTitle,
    this.animePoster,
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

  VideoPlayerController? _controller;
  bool _isPlayerReady = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
    _setLandscapeMode();
  }

  @override
  void dispose() {
    _controller?.dispose();
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

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    });
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    // Dispose old controller if exists
    await _controller?.dispose();
    
    setState(() {
      _isPlayerReady = false;
    });

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      await _controller!.initialize();
      
      setState(() {
        _isPlayerReady = true;
      });
      
      // Auto-play the video
      _controller!.play();
      
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
      
      // Listen to player state changes
      _controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      // Show toast instead of error screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load video. Try a different server.'),
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
      setState(() {
        _isPlayerReady = false;
        // Don't set global error, just reset player state
      });
    }
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

      setState(() {
        availableServers = servers;
        isLoadingServers = false;
        
        // Auto-select first server
        if (servers.isNotEmpty) {
          selectedServer = servers.first;
          selectedType = servers.first.type!;
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
    _loadStream();
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
                        // Video player
                        Center(
                          child: isLoadingStream
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : streamInfo != null && streamInfo!.streamingLink != null
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
                          child: AnimatedOpacity(
                            opacity: _showControls ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
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
                                          icon: const Icon(Icons.settings, color: Colors.white),
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
                                    ],
                                  ),
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
    if (_controller == null || !_isPlayerReady) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
        // Auto-hide controls after 3 seconds
        if (_showControls) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _controller!.value.isPlaying) {
              setState(() {
                _showControls = false;
              });
            }
          });
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            
            // Play/Pause overlay (center)
            if (!_controller!.value.isPlaying && _showControls)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            
            // Video controls overlay (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildVideoControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    if (_controller == null) return const SizedBox.shrink();

    final duration = _controller!.value.duration;
    final position = _controller!.value.position;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 8),
          
          // Control buttons and time
          Row(
            children: [
              // Play/Pause button
              IconButton(
                icon: Icon(
                  _controller!.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                },
              ),
              
              // Time display
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              
              const Spacer(),
              
              // Fullscreen toggle button
              IconButton(
                icon: Icon(
                  _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
