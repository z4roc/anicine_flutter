import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/storage_service.dart';
import '../models/anime_details.dart';
import '../models/episode_and_schedule.dart';
import 'episodes_screen.dart';
import 'characters_screen.dart';
import 'video_player_screen.dart';

class AnimeDetailsScreen extends StatefulWidget {
  final String animeId;

  const AnimeDetailsScreen({super.key, required this.animeId});

  @override
  State<AnimeDetailsScreen> createState() => _AnimeDetailsScreenState();
}

class _AnimeDetailsScreenState extends State<AnimeDetailsScreen> {
  final AnimeApi _api = AnimeApi();
  Map<String, dynamic>? animeData;
  bool isLoading = true;
  String? error;
  bool isInWatchlist = false;
  
  // Episodes data
  List<EpisodeItem> episodes = [];
  List<EpisodeItem> filteredEpisodes = [];
  int? totalEpisodes;
  bool isLoadingEpisodes = true;
  String? episodesError;
  final TextEditingController _episodeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAnimeDetails();
    _checkWatchlistStatus();
    _loadEpisodes();
    _episodeSearchController.addListener(_filterEpisodes);
  }

  @override
  void dispose() {
    _episodeSearchController.dispose();
    super.dispose();
  }

  void _filterEpisodes() {
    final query = _episodeSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredEpisodes = episodes;
      } else {
        filteredEpisodes = episodes.where((episode) {
          final episodeNumber = episode.episodeNo.toString();
          final title = episode.title.toLowerCase();
          return episodeNumber.contains(query) || title.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      isLoadingEpisodes = true;
      episodesError = null;
    });

    try {
      final data = await _api.getEpisodes(widget.animeId);
      final results = data['results'];
      
      setState(() {
        totalEpisodes = results['totalEpisodes'] != null
            ? int.tryParse(results['totalEpisodes'].toString())
            : null;
        episodes = (results['episodes'] as List<dynamic>?)
            ?.map((e) => EpisodeItem.fromJson(e))
            .toList() ?? [];
        filteredEpisodes = episodes;
        isLoadingEpisodes = false;
      });
    } catch (e) {
      setState(() {
        episodesError = e.toString();
        isLoadingEpisodes = false;
      });
    }
  }

  Future<void> _checkWatchlistStatus() async {
    final inList = await StorageService.isInWatchlist(widget.animeId);
    setState(() {
      isInWatchlist = inList;
    });
  }

  Future<void> _toggleWatchlist() async {
    if (animeData == null) return;

    final details = AnimeDetails.fromJson(animeData!['data']);
    
    if (isInWatchlist) {
      await StorageService.removeFromWatchlist(widget.animeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from watchlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await StorageService.addToWatchlist(
        animeId: widget.animeId,
        animeTitle: details.title,
        animePoster: details.poster ?? '',
        animeType: details.showType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to watchlist'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() {
      isInWatchlist = !isInWatchlist;
    });
  }

  Future<void> _loadAnimeDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _api.getAnimeDetails(widget.animeId);
      setState(() {
        // Extract results if present, otherwise use the data as-is
        animeData = data['results'] ?? data;
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnimeDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildDetailsContent(),
    );
  }

  Widget _buildDetailsContent() {
    if (animeData == null) {
      return const Center(child: Text('No data available'));
    }

    final animeDetails = AnimeDetails.fromJson(animeData!['data']);
    final seasons = (animeData!['seasons'] as List<dynamic>?)
        ?.map((e) => Season.fromJson(e))
        .toList();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          actions: [
            // Watchlist button
            IconButton(
              icon: Icon(
                isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
              ),
              tooltip: isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
              onPressed: _toggleWatchlist,
            ),
            // Characters button
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Characters',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharactersScreen(
                      animeId: animeDetails.id,
                      animeTitle: animeDetails.title,
                    ),
                  ),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              animeDetails.title,
              style: const TextStyle(
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            background: animeDetails.poster != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        animeDetails.poster!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, size: 64),
                          );
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.movie, size: 64),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Japanese Title
                if (animeDetails.japaneseTitle != null) ...[
                  Text(
                    animeDetails.japaneseTitle!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Info badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (animeDetails.showType != null)
                      Chip(label: Text(animeDetails.showType!)),
                    if (animeDetails.animeInfo?.status != null)
                      Chip(label: Text(animeDetails.animeInfo!.status!)),
                    if (animeDetails.animeInfo?.malScore != null)
                      Chip(
                        label: Text('⭐ ${animeDetails.animeInfo!.malScore}'),
                        backgroundColor: Colors.amber.withOpacity(0.3),
                      ),
                    if (animeDetails.adultContent == true)
                      Chip(
                        label: const Text('18+'),
                        backgroundColor: Colors.red.withOpacity(0.3),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Genres
                if (animeDetails.animeInfo?.genres != null && 
                    animeDetails.animeInfo!.genres!.isNotEmpty) ...[
                  const Text(
                    'Genres',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: animeDetails.animeInfo!.genres!
                        .map((genre) => Chip(
                              label: Text(genre),
                              backgroundColor: Colors.blue.withOpacity(0.2),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Overview/Description
                if (animeDetails.animeInfo?.overview != null) ...[
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    animeDetails.animeInfo!.overview!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],

                // Additional Info
                if (animeDetails.animeInfo != null) ...[
                  const Text(
                    'Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Aired', animeDetails.animeInfo!.aired),
                  _buildInfoRow('Premiered', animeDetails.animeInfo!.premiered),
                  _buildInfoRow('Duration', animeDetails.animeInfo!.duration),
                  _buildInfoRow('Studios', animeDetails.animeInfo!.studios),
                  if (animeDetails.animeInfo!.producers != null)
                    _buildInfoRow('Producers', 
                        animeDetails.animeInfo!.producers!.join(', ')),
                  if (animeDetails.animeInfo!.synonyms != null)
                    _buildInfoRow('Synonyms', animeDetails.animeInfo!.synonyms),
                  const SizedBox(height: 16),
                ],

                // Episodes Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Episodes${totalEpisodes != null ? " ($totalEpisodes)" : ""}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (episodes.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EpisodesScreen(
                                animeId: animeDetails.id,
                                animeTitle: animeDetails.title,
                                animePoster: animeDetails.poster,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('View All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Episode search bar
                if (episodes.isNotEmpty)
                  TextField(
                    controller: _episodeSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search episodes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _episodeSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _episodeSearchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Seasons
                if (seasons != null && seasons.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Seasons',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        
        // Episodes List
        if (isLoadingEpisodes)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (episodesError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error loading episodes: $episodesError'),
                  ],
                ),
              ),
            ),
          )
        else if (filteredEpisodes.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  _episodeSearchController.text.isEmpty
                      ? 'No episodes available'
                      : 'No episodes match your search',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final episode = filteredEpisodes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          '${episode.episodeNo}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        episode.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.play_circle_outline),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              episodeId: episode.id,
                              episodeTitle: episode.title,
                              episodeNumber: episode.episodeNo,
                              animeId: animeDetails.id,
                              animeTitle: animeDetails.title,
                              animePoster: animeDetails.poster,
                              allEpisodes: episodes.map((ep) => {
                                'id': ep.id,
                                'episode_no': ep.episodeNo,
                                'title': ep.title,
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: filteredEpisodes.length,
              ),
            ),
          ),
        
        // Seasons List (if any)
        if (seasons != null && seasons.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final season = seasons[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: season.seasonPoster != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              season.seasonPoster!,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 70,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.movie, size: 24),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 70,
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, size: 24),
                          ),
                    title: Text(season.title),
                    subtitle: season.season != null 
                        ? Text(season.season!)
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showSeasonDialog(season);
                    },
                  ),
                );
              },
              childCount: seasons.length,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showSeasonDialog(Season season) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(season.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (season.seasonPoster != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  season.seasonPoster!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, size: 64),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (season.japaneseTitle != null)
              Text(
                season.japaneseTitle!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (season.season != null) ...[
              const SizedBox(height: 8),
              Text('Season: ${season.season}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to episodes screen with season ID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodesScreen(
                    animeId: season.id,
                    animeTitle: season.title,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('View Episodes'),
          ),
        ],
      ),
    );
  }
}
