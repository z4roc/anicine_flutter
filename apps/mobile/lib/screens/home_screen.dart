import 'dart:developer';

import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/anime.dart';
import 'anime_details_screen.dart';
import 'category_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      setState(() {
        log(data.toString());
        // Extract the results object from the response
        homeData = data['results'];
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
      appBar: AppBar(
        title: const Text('AniCine Home'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.category),
            tooltip: 'Categories',
            onSelected: (category) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(category: category),
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'top-airing', child: Text('Top Airing')),
              const PopupMenuItem(value: 'most-popular', child: Text('Most Popular')),
              const PopupMenuItem(value: 'most-favorite', child: Text('Most Favorite')),
              const PopupMenuItem(value: 'recently-updated', child: Text('Recently Updated')),
              const PopupMenuItem(value: 'genre/action', child: Text('Action')),
              const PopupMenuItem(value: 'genre/comedy', child: Text('Comedy')),
              const PopupMenuItem(value: 'genre/drama', child: Text('Drama')),
              const PopupMenuItem(value: 'genre/romance', child: Text('Romance')),
              const PopupMenuItem(value: 'movie', child: Text('Movies')),
              const PopupMenuItem(value: 'tv', child: Text('TV Series')),
            ],
          ),
        ],
      ),
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
                        onPressed: _loadHomeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHomeData,
                  child: _buildHomeContent(),
                ),
    );
  }

  Widget _buildHomeContent() {
    if (homeData == null) {
      return const Center(child: Text('No data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Spotlight Anime
        if (homeData!['spotlights'] != null)
          _buildSpotlightSection(homeData!['spotlights']),
        
        const SizedBox(height: 16),
        
        // Trending Animes
        if (homeData!['trending'] != null)
          _buildAnimeSection('Trending Now', homeData!['trending']),
        
        // Top Airing
        if (homeData!['topAiring'] != null)
          _buildAnimeSection('Top Airing', homeData!['topAiring']),
        
        // Most Popular
        if (homeData!['mostPopular'] != null)
          _buildAnimeSection('Most Popular', homeData!['mostPopular']),
        
        // Most Favorite
        if (homeData!['mostFavorite'] != null)
          _buildAnimeSection('Most Favorite', homeData!['mostFavorite']),
        
        // Latest Episodes
        if (homeData!['latestEpisode'] != null)
          _buildAnimeSection('Latest Episodes', homeData!['latestEpisode']),
        
        // Latest Completed
        if (homeData!['latestCompleted'] != null)
          _buildAnimeSection('Latest Completed', homeData!['latestCompleted']),
      ],
    );
  }

  Widget _buildSpotlightSection(List<dynamic> animes) {
    if (animes.isEmpty) return const SizedBox();

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: animes.length,
        itemBuilder: (context, index) {
          final anime = Anime.fromJson(animes[index]);
          return GestureDetector(
            onTap: () => _navigateToDetails(anime.id),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (anime.poster != null)
                    Image.network(
                      anime.poster!,
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
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (anime.description != null)
                          Text(
                            anime.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
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

  Widget _buildAnimeSection(String title, List<dynamic> animes) {
    if (animes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: animes.length,
            itemBuilder: (context, index) {
              final anime = Anime.fromJson(animes[index]);
              return _buildAnimeCard(anime);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () => _navigateToDetails(anime.id),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: anime.poster != null
                    ? Image.network(
                        anime.poster!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, size: 48),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, size: 48),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              anime.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(String animeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimeDetailsScreen(animeId: animeId),
      ),
    );
  }
}
