import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/anime.dart';
import 'anime_details_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final AnimeApi _api = AnimeApi();
  List<Anime> animeList = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _api.getCategory(widget.category);
      // Extract results from the response
      final resultsData = data['results'];
      final results = (resultsData['animes'] as List<dynamic>?)
          ?.map((e) => Anime.fromJson(e))
          .toList() ?? [];
      
      setState(() {
        animeList = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String _getCategoryTitle() {
    return widget.category
        .split('-')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ')
        .replaceAll('Genre/', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
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
                        onPressed: _loadCategoryData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : animeList.isEmpty
                  ? const Center(child: Text('No anime found in this category'))
                  : RefreshIndicator(
                      onRefresh: _loadCategoryData,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: animeList.length,
                        itemBuilder: (context, index) {
                          final anime = animeList[index];
                          return _buildAnimeCard(anime);
                        },
                      ),
                    ),
    );
  }

  Widget _buildAnimeCard(Anime anime) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailsScreen(animeId: anime.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (anime.type != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      anime.type!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
