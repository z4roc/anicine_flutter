import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './services/api.dart';
import './models/anime.dart';
import './screens/tv_episodes_screen.dart';
import './services/storage_service.dart';

class TVAnimeDetailsScreen extends StatefulWidget {
  final String animeId;

  const TVAnimeDetailsScreen({super.key, required this.animeId});

  @override
  State<TVAnimeDetailsScreen> createState() => _TVAnimeDetailsScreenState();
}

class _TVAnimeDetailsScreenState extends State<TVAnimeDetailsScreen> {
  final AnimeApi _api = AnimeApi();
  Anime? anime;
  bool isLoading = true;
  String? error;
  bool isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _loadAnimeDetails();
    _checkWatchlist();
  }

  Future<void> _checkWatchlist() async {
    final watchlist = await StorageService.getWatchlist();
    setState(() {
      isInWatchlist = watchlist.any((item) => item['animeId'] == widget.animeId);
    });
  }

  Future<void> _toggleWatchlist() async {
    if (anime == null) return;
    
    if (isInWatchlist) {
      await StorageService.removeFromWatchlist(widget.animeId);
    } else {
      await StorageService.addToWatchlist(
        animeId: widget.animeId,
        animeTitle: anime!.name,
        animePoster: anime!.poster ?? '',
      );
    }
    
    setState(() {
      isInWatchlist = !isInWatchlist;
    });
  }

  void _navigateToEpisodes() {
    if (anime == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TVEpisodesScreen(
          animeId: widget.animeId,
          animeTitle: anime!.name,
          animePoster: anime!.poster,
        ),
      ),
    );
  }

  Future<void> _loadAnimeDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _api.getAnimeDetails(widget.animeId);
      // The API returns data wrapped in 'results' key
      final animeData = data['results']['data'] ?? data;
      setState(() {
        anime = Anime.fromJson(animeData);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null || anime == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${error ?? "Unknown error"}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Background image with gradient
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                anime!.poster!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey.shade900);
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.enter)) {
                      Navigator.pop(context);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return Container(
                        decoration: BoxDecoration(
                          color: isFocused
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 32,
                          onPressed: () => Navigator.pop(context),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                // Anime info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Poster
                    Container(
                      width: 220,
                      height: 330,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          anime!.poster!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.broken_image, size: 64),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anime!.name,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (anime!.description != null) ...[
                            Text(
                              anime!.description!,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.5,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 24),
                          ],
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (anime!.type != null)
                                _buildInfoChip(
                                  Icons.tv,
                                  anime!.type!,
                                ),
                              if (anime!.status != null)
                                _buildInfoChip(
                                  Icons.info,
                                  anime!.status!,
                                ),
                              if (anime!.releaseDate != null)
                                _buildInfoChip(
                                  Icons.calendar_today,
                                  anime!.releaseDate!,
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Action Buttons
                          Row(
                            children: [
                              _buildActionButton(
                                icon: Icons.play_arrow,
                                label: 'Watch Episodes',
                                onPressed: _navigateToEpisodes,
                                isPrimary: true,
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: isInWatchlist ? Icons.check : Icons.add,
                                label: isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                                onPressed: _toggleWatchlist,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData? icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: isPrimary
                    ? (isFocused ? Colors.purple.shade700 : Colors.purple)
                    : (isFocused
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
                border: isFocused
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}