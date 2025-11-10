import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _watchHistoryKey = 'watch_history';
  static const String _watchlistKey = 'watchlist';

  // Watch History Item
  static Future<void> addToWatchHistory({
    required String animeId,
    required String animeTitle,
    required String animePoster,
    required int episodeNumber,
    required String episodeId,
    required String episodeTitle,
    int? lastPosition, // Position in seconds
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_watchHistoryKey);
    
    List<dynamic> history = [];
    if (historyJson != null) {
      history = jsonDecode(historyJson);
    }

    // Check if this anime already exists in history
    final existingIndex = history.indexWhere((item) => item['animeId'] == animeId);
    
    final newItem = {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'animePoster': animePoster,
      'episodeNumber': episodeNumber,
      'episodeId': episodeId,
      'episodeTitle': episodeTitle,
      'lastPosition': lastPosition ?? 0,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (existingIndex != -1) {
      // Update existing entry and move to top
      history.removeAt(existingIndex);
    }
    
    // Add to beginning of list (most recent first)
    history.insert(0, newItem);
    
    // Keep only last 50 items
    if (history.length > 50) {
      history = history.sublist(0, 50);
    }

    await prefs.setString(_watchHistoryKey, jsonEncode(history));
  }

  static Future<List<Map<String, dynamic>>> getWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_watchHistoryKey);
    
    if (historyJson == null) {
      return [];
    }

    final List<dynamic> history = jsonDecode(historyJson);
    return history.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<void> clearWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchHistoryKey);
  }

  static Future<Map<String, dynamic>?> getAnimeProgress(String animeId) async {
    final history = await getWatchHistory();
    try {
      return history.firstWhere((item) => item['animeId'] == animeId);
    } catch (e) {
      return null;
    }
  }

  // Watchlist
  static Future<void> addToWatchlist({
    required String animeId,
    required String animeTitle,
    required String animePoster,
    String? animeType,
    double? animeRating,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistJson = prefs.getString(_watchlistKey);
    
    List<dynamic> watchlist = [];
    if (watchlistJson != null) {
      watchlist = jsonDecode(watchlistJson);
    }

    // Check if already in watchlist
    final exists = watchlist.any((item) => item['animeId'] == animeId);
    if (exists) {
      return; // Already in watchlist
    }

    final newItem = {
      'animeId': animeId,
      'animeTitle': animeTitle,
      'animePoster': animePoster,
      'animeType': animeType,
      'animeRating': animeRating,
      'addedAt': DateTime.now().toIso8601String(),
    };

    watchlist.insert(0, newItem);

    await prefs.setString(_watchlistKey, jsonEncode(watchlist));
  }

  static Future<void> removeFromWatchlist(String animeId) async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistJson = prefs.getString(_watchlistKey);
    
    if (watchlistJson == null) return;

    List<dynamic> watchlist = jsonDecode(watchlistJson);
    watchlist.removeWhere((item) => item['animeId'] == animeId);

    await prefs.setString(_watchlistKey, jsonEncode(watchlist));
  }

  static Future<List<Map<String, dynamic>>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistJson = prefs.getString(_watchlistKey);
    
    if (watchlistJson == null) {
      return [];
    }

    final List<dynamic> watchlist = jsonDecode(watchlistJson);
    return watchlist.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<bool> isInWatchlist(String animeId) async {
    final watchlist = await getWatchlist();
    return watchlist.any((item) => item['animeId'] == animeId);
  }

  static Future<void> clearWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchlistKey);
  }

  // Episode progress tracking (for resume functionality)
  static Future<void> saveEpisodeProgress({
    required String episodeId,
    required int position, // Position in seconds
    required int duration, // Duration in seconds
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressKey = 'episode_progress_$episodeId';
    
    final data = {
      'position': position,
      'duration': duration,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString(progressKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getEpisodeProgress(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressKey = 'episode_progress_$episodeId';
    final progressJson = prefs.getString(progressKey);
    
    if (progressJson == null) {
      return null;
    }

    return Map<String, dynamic>.from(jsonDecode(progressJson));
  }

  // Server preference
  static const String _preferredServerKey = 'preferred_server';

  static Future<void> savePreferredServer(String serverName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredServerKey, serverName);
  }

  static Future<String?> getPreferredServer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredServerKey);
  }
}
