import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';
import '../models/episode_and_schedule.dart';
import 'tv_video_player_screen.dart';

class TVEpisodesScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  final String? animePoster;

  const TVEpisodesScreen({
    super.key,
    required this.animeId,
    required this.animeTitle,
    this.animePoster,
  });

  @override
  State<TVEpisodesScreen> createState() => _TVEpisodesScreenState();
}

class _TVEpisodesScreenState extends State<TVEpisodesScreen> {
  final AnimeApi _api = AnimeApi();
  final TextEditingController _searchController = TextEditingController();
  List<EpisodeItem> _allEpisodes = [];
  List<EpisodeItem> _displayedEpisodes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getEpisodes(widget.animeId);
      final results = data['results'];
      
      final episodes = (results['episodes'] as List<dynamic>?)
          ?.map((e) => EpisodeItem.fromJson(e))
          .toList() ?? [];

      if (mounted) {
        setState(() {
          _allEpisodes = episodes;
          _displayedEpisodes = episodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterEpisodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedEpisodes = _allEpisodes;
      } else {
        _displayedEpisodes = _allEpisodes.where((episode) {
          final episodeNumber = episode.episodeNo.toString();
          final episodeTitle = episode.title.toLowerCase();
          final searchLower = query.toLowerCase();
          return episodeNumber.contains(searchLower) ||
              episodeTitle.contains(searchLower);
        }).toList();
      }
    });
  }

  void _playEpisode(EpisodeItem episode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TVVideoPlayerScreen(
          episodeId: episode.id,
          episodeNumber: episode.episodeNo,
          animeTitle: widget.animeTitle,
          animePoster: widget.animePoster,
          animeId: widget.animeId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900.withOpacity(0.3),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Focus(
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
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: isFocused
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
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
                    const SizedBox(width: 24),
                    if (widget.animePoster != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.animePoster!,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 120,
                            color: Colors.grey[800],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.animeTitle,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_allEpisodes.length} Episodes',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Focus(
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: isFocused
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterEpisodes,
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          decoration: InputDecoration(
                            hintText: 'Search episodes...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 18,
                            ),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.7),
                              size: 28,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterEpisodes('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Episodes Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 80,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : _displayedEpisodes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No episodes found',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(24),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 16 / 10,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: _displayedEpisodes.length,
                                itemBuilder: (context, index) {
                                  final episode = _displayedEpisodes[index];
                                  return _buildEpisodeCard(episode, isFirstItem: index == 0);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeCard(EpisodeItem episode, {bool isFirstItem = false}) {
    return Focus(
      autofocus: isFirstItem,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onTap: () => _playEpisode(episode),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isFocused ? 0.2 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: isFocused
                    ? Border.all(color: Colors.white, width: 4)
                    : null,
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),

                  // Episode info
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Episode ${episode.episodeNo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            episode.title,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Play icon overlay when focused
                  if (isFocused)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
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
