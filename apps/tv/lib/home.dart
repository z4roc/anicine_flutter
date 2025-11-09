import 'package:anicinehome_tv/anime_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api.dart';
import 'models/anime.dart';

class TVHomeScreen extends StatefulWidget {
  const TVHomeScreen({super.key});

  @override
  State<TVHomeScreen> createState() => _TVHomeScreenState();
}

class _TVHomeScreenState extends State<TVHomeScreen> {
  final AnimeApi _api = AnimeApi();
  Map<String, dynamic>? homeData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _api.getHome();
      if (mounted) {
        setState(() {
          homeData = data['results'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        children: [
          Icon(Icons.tv, size: 48, color: Colors.deepPurple.shade300),
          const SizedBox(width: 16),
          const Text(
            'AniCine TV',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHomeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (homeData == null) {
      return const Center(child: Text('No data available'));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Spotlight Section
        if (homeData!['spotlights'] != null && (homeData!['spotlights'] as List).isNotEmpty) ...[
          _buildSpotlight(homeData!['spotlights']),
          const SizedBox(height: 48),
        ],
        
        // Trending Now
        if (homeData!['trending'] != null)
          _buildSection('Trending Now', homeData!['trending']),
        
        const SizedBox(height: 48),
        
        // Top Airing
        if (homeData!['topAiring'] != null)
          _buildSection('Top Airing', homeData!['topAiring']),
        
        const SizedBox(height: 48),
        
        // Most Popular
        if (homeData!['mostPopular'] != null)
          _buildSection('Most Popular', homeData!['mostPopular']),
        
        const SizedBox(height: 48),
        
        // Most Favorite
        if (homeData!['mostFavorite'] != null)
          _buildSection('Most Favorite', homeData!['mostFavorite']),
        
        const SizedBox(height: 48),
        
        // Latest Episodes
        if (homeData!['latestEpisode'] != null)
          _buildSection('Latest Episodes', homeData!['latestEpisode']),
        
        const SizedBox(height: 48),
        
        // Latest Completed
        if (homeData!['latestCompleted'] != null)
          _buildSection('Latest Completed', homeData!['latestCompleted']),
        
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSpotlight(List<dynamic> spotlight) {
    if (spotlight.isEmpty) return const SizedBox.shrink();

    // Show the first spotlight anime
    final anime = Anime.fromJson(spotlight[0]);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: FocusableActionDetector(
        onShowHoverHighlight: (highlight) {},
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              _navigateToDetails(anime);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Builder(
            builder: (context) {
              final isFocused = Focus.of(context).hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: isFocused
                      ? Border.all(color: Colors.white, width: 4)
                      : null,
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        anime.poster ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.broken_image, size: 64),
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
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 32,
                        left: 32,
                        right: 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anime.name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (anime.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                anime.description!,
                                style: const TextStyle(fontSize: 16),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items) {
    final animeList = items.map((item) => Anime.fromJson(item)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: animeList.length,
              itemBuilder: (context, index) {
                return _buildAnimeCard(animeList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.enter)) {
            _navigateToDetails(anime);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isFocused
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        )
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        anime.poster ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.broken_image),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black.withOpacity(0.7),
                      child: Text(
                        anime.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDetails(Anime anime) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TVAnimeDetailsScreen(animeId: anime.id),
      ),
    );
  }
}