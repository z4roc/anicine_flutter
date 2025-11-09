import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../services/api.dart';
import '../services/storage_service.dart';
import '../models/stream.dart';

class TVVideoPlayerScreen extends StatefulWidget {
  final String episodeId;
  final int episodeNumber;
  final String animeTitle;
  final String? animePoster;
  final String? animeId;

  const TVVideoPlayerScreen({
    super.key,
    required this.episodeId,
    required this.episodeNumber,
    required this.animeTitle,
    this.animePoster,
    this.animeId,
  });

  @override
  State<TVVideoPlayerScreen> createState() => _TVVideoPlayerScreenState();
}

class _TVVideoPlayerScreenState extends State<TVVideoPlayerScreen> {
  final AnimeApi _api = AnimeApi();
  VideoPlayerController? _controller;
  List<Server> availableServers = [];
  Server? selectedServer;
  String selectedType = 'sub';
  bool isLoadingServers = true;
  bool isLoadingStream = false;
  String? error;
  bool _showControls = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
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

      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoadingServers = false;
        });
      }
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
        selectedServer!.serverName!,
        selectedType,
      );

      final streamInfo = StreamInfo.fromJson(data['results']);
      final videoUrl = streamInfo.streamingLink?.link?.file;

      if (videoUrl != null && mounted) {
        await _initializeVideoPlayer(videoUrl);
        
        // Save to watch history
        if (widget.animeId != null && widget.animePoster != null) {
          StorageService.addToWatchHistory(
            animeId: widget.animeId!,
            animeTitle: widget.animeTitle,
            animePoster: widget.animePoster!,
            episodeNumber: widget.episodeNumber,
            episodeId: widget.episodeId,
            episodeTitle: 'Episode ${widget.episodeNumber}',
          );
        }
      } else if (mounted) {
        // No video URL found - show toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No video stream available. Try selecting a different server.',
              style: TextStyle(fontSize: 16),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(24),
            action: availableServers.length > 1
                ? SnackBarAction(
                    label: 'Change Server',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _showControls = true;
                      });
                    },
                  )
                : null,
          ),
        );
        setState(() {
          _showControls = true; // Keep controls visible to switch servers
        });
      }

      setState(() {
        isLoadingStream = false;
      });
    } catch (e) {
      if (mounted) {
        // Show toast instead of error screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch stream. Try selecting a different server.',
              style: const TextStyle(fontSize: 16),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(24),
            action: availableServers.length > 1
                ? SnackBarAction(
                    label: 'Change Server',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _showControls = true;
                      });
                    },
                  )
                : null,
          ),
        );
        setState(() {
          isLoadingStream = false;
          _showControls = true; // Keep controls visible to switch servers
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    try {
      await _controller?.dispose();
      
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..addListener(() {
          if (mounted && _controller != null) {
            setState(() {
              _isPlaying = _controller!.value.isPlaying;
            });
            
            // Auto-hide controls after 3 seconds of no interaction
            if (_controller!.value.isPlaying && _showControls) {
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _controller != null && _controller!.value.isPlaying) {
                  setState(() {
                    _showControls = false;
                  });
                }
              });
            }
          }
        })
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller!.play();
          }
        }).catchError((e) {
          if (mounted) {
            // Show toast instead of error screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Failed to load video. Try selecting a different server.',
                  style: TextStyle(fontSize: 16),
                ),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red.shade800,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(24),
                action: availableServers.length > 1
                    ? SnackBarAction(
                        label: 'Change Server',
                        textColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            _showControls = true;
                          });
                        },
                      )
                    : null,
              ),
            );
            setState(() {
              _showControls = true; // Keep controls visible to switch servers
              // Don't set global error, just reset player state
            });
          }
        });
    } catch (e) {
      if (mounted) {
        // Show toast instead of error screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error initializing video. Try selecting a different server.',
              style: const TextStyle(fontSize: 16),
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(24),
            action: availableServers.length > 1
                ? SnackBarAction(
                    label: 'Change Server',
                    textColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _showControls = true;
                      });
                    },
                  )
                : null,
          ),
        );
        setState(() {
          _showControls = true; // Keep controls visible to switch servers
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  void _seekForward() {
    if (_controller != null && _controller!.value.isInitialized) {
      final current = _controller!.value.position;
      final target = current + const Duration(seconds: 10);
      _controller!.seekTo(target);
      setState(() {
        _showControls = true;
      });
    }
  }

  void _seekBackward() {
    if (_controller != null && _controller!.value.isInitialized) {
      final current = _controller!.value.position;
      final target = current - const Duration(seconds: 10);
      _controller!.seekTo(target > Duration.zero ? target : Duration.zero);
      setState(() {
        _showControls = true;
      });
    }
  }

  void _changeServer(int index) async {
    if (availableServers.isNotEmpty && index < availableServers.length) {
      setState(() {
        selectedServer = availableServers[index];
        selectedType = availableServers[index].type!;
      });
      await _loadStream();
    }
  }

  void _showServerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Server'),
          content: SizedBox(
            width: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableServers.length,
              itemBuilder: (context, index) {
                final server = availableServers[index];
                final isSelected = selectedServer == server;
                return Focus(
                  autofocus: isSelected,
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _changeServer(index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.purple.withOpacity(0.3)
                                : isFocused
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isFocused
                                ? Border.all(color: Colors.white, width: 2)
                                : Border.all(
                                    color: isSelected
                                        ? Colors.purple
                                        : Colors.transparent,
                                    width: 2),
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 24)
                              else
                                const SizedBox(width: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      server.serverName ?? 'Server ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (server.type != null)
                                      Text(
                                        server.type!.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.5),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            Focus(
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: isFocused
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      side: isFocused
                          ? const BorderSide(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: _controller != null && _controller!.value.isInitialized,
        skipTraversal: _controller == null || !_controller!.value.isInitialized,
        onKeyEvent: (node, event) {
          // Only handle video controls when video is actually playing
          if (_controller != null && _controller!.value.isInitialized) {
            if (event is KeyDownEvent) {
              setState(() {
                _showControls = true;
              });

              if (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter) {
                _togglePlayPause();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _seekForward();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _seekBackward();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.goBack ||
                         event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(context);
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // Video Player
            if (_controller != null && _controller!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else if (isLoadingServers || isLoadingStream)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              // Show placeholder when no video is loaded
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.animePoster != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.animePoster!,
                          width: 200,
                          height: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 200,
                            height: 280,
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, size: 80, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      const Icon(Icons.movie, size: 120, color: Colors.white54),
                    const SizedBox(height: 20),
                    Text(
                      widget.animeTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Episode ${widget.episodeNumber}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 40),
                      Text(
                        'Select a different server to continue',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Server Selection Overlay (always show when no video or controls are visible)
            if (!isLoadingServers && !isLoadingStream && availableServers.isNotEmpty &&
                (_controller == null || !_controller!.value.isInitialized || _showControls))
              Positioned(
                top: 24,
                right: 24,
                child: SafeArea(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (availableServers.length > 1)
                        Focus(
                          child: Builder(
                            builder: (context) {
                              final isFocused = Focus.of(context).hasFocus;
                              return InkWell(
                                onTap: _showServerSelectionDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isFocused 
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isFocused
                                        ? Border.all(color: Colors.white, width: 3)
                                        : Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.dns, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Server: ${selectedServer?.serverName ?? "Unknown"}',
                                        style: const TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Back button overlay (always accessible)
            if (_controller == null || !_controller!.value.isInitialized)
              Positioned(
                top: 24,
                left: 24,
                child: SafeArea(
                  child: Focus(
                    autofocus: true,
                    child: Builder(
                      builder: (context) {
                        final isFocused = Focus.of(context).hasFocus;
                        return InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isFocused
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: isFocused
                                  ? Border.all(color: Colors.white, width: 3)
                                  : Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            // Video Controls Overlay
            if (_showControls && _controller != null && _controller!.value.isInitialized)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            if (widget.animePoster != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.animePoster!,
                                  width: 60,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 80,
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.animeTitle,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Episode ${widget.episodeNumber}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Server Selection
                            if (availableServers.length > 1 && selectedServer != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.dns, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Server: ${selectedServer!.serverName}',
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Controls
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Progress Bar
                            VideoProgressIndicator(
                              _controller!,
                              allowScrubbing: false,
                              colors: VideoProgressColors(
                                playedColor: Theme.of(context).colorScheme.primary,
                                bufferedColor: Colors.white.withOpacity(0.3),
                                backgroundColor: Colors.white.withOpacity(0.1),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            const SizedBox(height: 12),
                            
                            // Time and Controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildControlButton(
                                      icon: Icons.replay_10,
                                      label: 'Rewind',
                                      onPressed: _seekBackward,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildControlButton(
                                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                                      label: _isPlaying ? 'Pause' : 'Play',
                                      onPressed: _togglePlayPause,
                                      isLarge: true,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildControlButton(
                                      icon: Icons.forward_10,
                                      label: 'Forward',
                                      onPressed: _seekForward,
                                    ),
                                  ],
                                ),
                                if (availableServers.length > 1)
                                  Focus(
                                    child: Builder(
                                      builder: (context) {
                                        final isFocused = Focus.of(context).hasFocus;
                                        return InkWell(
                                          onTap: _showServerSelectionDialog,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isFocused 
                                                  ? Colors.white.withOpacity(0.3)
                                                  : Colors.white.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                              border: isFocused
                                                  ? Border.all(color: Colors.white, width: 3)
                                                  : null,
                                            ),
                                            child: const Icon(
                                              Icons.dns,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            
                            // D-pad Instructions
                            const SizedBox(height: 16),
                            Text(
                              'D-pad: ◀ Rewind | ▶ Forward | ⏎ Play/Pause | ◀ Back',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.all(isLarge ? 16 : 12),
              decoration: BoxDecoration(
                color: isFocused 
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isFocused
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isLarge ? 40 : 32,
              ),
            ),
          );
        },
      ),
    );
  }
}
