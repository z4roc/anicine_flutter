import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/episode_and_schedule.dart';

class CharactersScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  const CharactersScreen({
    super.key,
    required this.animeId,
    required this.animeTitle,
  });

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final AnimeApi _api = AnimeApi();
  List<CharacterWithVoiceActors> characters = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _api.getCharacters(widget.animeId);
      final results = data['results'];
      
      setState(() {
        currentPage = results['currentPage'] != null
            ? int.tryParse(results['currentPage'].toString()) ?? 1
            : 1;
        totalPages = results['totalPages'] != null
            ? int.tryParse(results['totalPages'].toString()) ?? 1
            : 1;
        characters = (results['data'] as List<dynamic>?)
            ?.map((e) => CharacterWithVoiceActors.fromJson(e))
            .toList() ?? [];
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.animeTitle,
              style: const TextStyle(fontSize: 16),
            ),
            const Text(
              'Characters & Voice Actors',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
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
                        onPressed: _loadCharacters,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : characters.isEmpty
                  ? const Center(child: Text('No characters available'))
                  : Column(
                      children: [
                        if (totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Page $currentPage of $totalPages',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: characters.length,
                            itemBuilder: (context, index) {
                              final item = characters[index];
                              return _buildCharacterCard(item);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildCharacterCard(CharacterWithVoiceActors item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Character info
            Row(
              children: [
                // Character image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.character.poster != null
                      ? Image.network(
                          item.character.poster!,
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 80,
                              color: Colors.grey[800],
                              child: const Icon(Icons.person, size: 30),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 80,
                          color: Colors.grey[800],
                          child: const Icon(Icons.person, size: 30),
                        ),
                ),
                const SizedBox(width: 12),
                // Character details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.character.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.character.cast != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.character.cast!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Voice actors
            if (item.voiceActors.isNotEmpty) ...[
              const Divider(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Voice Actors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...item.voiceActors.map((va) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipOval(
                          child: va.poster != null
                              ? Image.network(
                                  va.poster!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.mic, size: 20),
                                    );
                                  },
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.mic, size: 20),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            va.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
