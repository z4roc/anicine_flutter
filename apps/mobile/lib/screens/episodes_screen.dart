import 'package:flutter/material.dart';
import '../services/api.dart';
import '../models/episode_and_schedule.dart';
import 'video_player_screen.dart';

class EpisodesScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  final String? animePoster;

  const EpisodesScreen({
    super.key,
    required this.animeId,
    required this.animeTitle,
    this.animePoster,
  });

  @override
  State<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends State<EpisodesScreen> {
  final AnimeApi _api = AnimeApi();
  List<EpisodeItem> episodes = [];
  int? totalEpisodes;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      isLoading = true;
      error = null;
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
            if (totalEpisodes != null)
              Text(
                '$totalEpisodes Episodes',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
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
                        onPressed: _loadEpisodes,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : episodes.isEmpty
                  ? const Center(child: Text('No episodes available'))
                  : ListView.builder(
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                '${episode.episodeNo}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(episode.title),
                            subtitle: episode.japaneseTitle != null
                                ? Text(
                                    episode.japaneseTitle!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                : null,
                            trailing: const Icon(Icons.play_circle_outline, size: 32),
                            onTap: () {
                              _showEpisodeDialog(episode);
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  void _showEpisodeDialog(EpisodeItem episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Episode ${episode.episodeNo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (episode.japaneseTitle != null) ...[
              const SizedBox(height: 8),
              Text(
                episode.japaneseTitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Select servers and start watching this episode.',
            ),
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
              // Navigate to video player screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(
                    episodeId: episode.id,
                    episodeTitle: episode.title,
                    episodeNumber: episode.episodeNo,
                    animeId: widget.animeId,
                    animeTitle: widget.animeTitle,
                    animePoster: widget.animePoster,
                    allEpisodes: episodes.map((ep) => {
                      'id': ep.id,
                      'episode_no': ep.episodeNo,
                      'title': ep.title,
                    }).toList(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Watch Now'),
          ),
        ],
      ),
    );
  }
}
