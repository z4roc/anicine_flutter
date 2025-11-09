import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart';

class AnimeApi {
  final List<String> categories = [
    'top-airing',
    'most-popular',
    'most-favorite',
    'completed',
    'recently-updated',
    'recently-added',
    'top-upcoming',
    'subbed-anime',
    'dubbed-anime',
    'genre/action',
    'genre/adventure',
    'genre/cars',
    'genre/comedy',
    'genre/dementia',
    'genre/demons',
    'genre/drama',
    'genre/ecchi',
    'genre/fantasy',
    'genre/game',
    'genre/harem',
    'genre/historical',
    'genre/horror',
    'genre/isekai',
    'genre/josei',
    'genre/kids',
    'genre/magic',
    'genre/martial-arts',
    'genre/mecha',
    'genre/military',
    'genre/music',
    'genre/mystery',
    'genre/parody',
    'genre/police',
    'genre/psychological',
    'genre/romance',
    'genre/samurai',
    'genre/school',
    'genre/sci-fi',
    'genre/seinen',
    'genre/shoujo',
    'genre/shoujo-ai',
    'genre/shounen',
    'genre/shounen-ai',
    'genre/slice-of-life',
    'genre/space',
    'genre/sports',
    'genre/super-power',
    'genre/supernatural',
    'genre/thriller',
    'genre/vampire',
    'az-list',
    'az-list/other',
    'az-list/0-9',
    'az-list/a',
    'az-list/b',
    'az-list/c',
    'az-list/d',
    'az-list/e',
    'az-list/f',
    'az-list/g',
    'az-list/h',
    'az-list/i',
    'az-list/j',
    'az-list/k',
    'az-list/l',
    'az-list/m',
    'az-list/n',
    'az-list/o',
    'az-list/p',
    'az-list/q',
    'az-list/r',
    'az-list/s',
    'az-list/t',
    'az-list/u',
    'az-list/v',
    'az-list/w',
    'az-list/x',
    'az-list/y',
    'az-list/z',
    'movie',
    'special',
    'ova',
    'ona',
    'tv',
  ];

  static String baseUrl = dotenv.env['API_BASEURL'] ?? "";

  Future<Map<String, dynamic>> _fetchData(String endpoint) async {
    final response = await get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load data');
    }
    
  }

  Future<Map<String, dynamic>> getHome() async {
    return await _fetchData('');
  }

  Future<Map<String, dynamic>> getTopTen() async {
    return await _fetchData('/top-ten');
  }

  Future<Map<String, dynamic>> getAnimeDetails(String id) async {
    return await _fetchData('/info?id=$id');
  }

  Future<Map<String, dynamic>> getRandomAnime() async {
    return await _fetchData('/random');
  }

  Future<Map<String, dynamic>> getCategory(String category) async {
    return await _fetchData('/$category');
  }
  /* Search Anime
  {
    "success": true,
    "results": [
      {
          "id":string,
          "data_id": number,
          "poster": string,
          "title": string,
          "japanese_title": string,
          "tvInfo": [Object]
        },
      {
          "id":string,
          "data_id": number,
          "poster": string,
          "title": string,
          "japanese_title": string,
          "tvInfo": [Object]
        },
      {...}
    ]
  }
  */
  Future<Map<String, dynamic>> searchAnime(String query) async {
    return await _fetchData('/search?keyword=$query');
  }
  /* Get Episodes
  {
    "success": true,
    "results": [
      "totalEpisodes":number,
      "episodes":[
      { "episode_no": number,
        "id": string,
        "data_id": number,
        "jname": string,
        "title": string,
        "japanese_title": string
      },
      {...}
      ]
    ]
  }
   */
  Future<Map<String, dynamic>> getEpisodes(String id) async {
    return await _fetchData('/episodes/$id');
  }
  /* Get Schedule
    {
  "success": true,
  "results": [
    {
      "id":string,
      "data_id":number,
      "title":string,
      "japanese_title":string,
      "releaseDate":string,
      "time":string,
      "episode_no":number
    },
    {...}
  ]
}
   */
  Future<Map<String, dynamic>> getSchedule(String date) async {
    return await _fetchData('/schedule?date=$date');
  }
  /*
  {
    "success":true,
    "results":
    {
      "nextEpisodeSchedule":"2025-02-08 16:30:00"
    }
  }
   */
  Future<Map<String, dynamic>> getNextAnimeEpisode(String id) async {
    return await _fetchData('/schedule/$id');
  }
  /*
  Character List

  {
  "success": true,
  "results": {
    "currentPage": number,
    "totalPages": number,
    "data": [
      {
        "character": {
          "id": string,
          "poster": string,
          "name": string,
          "cast": string
        },
        "voiceActors": [
          {
            "id": string,
            "poster": string,
            "name": string
          },
          {
            "id": string,
            "poster": string,
            "name": string
          },
          {...}
        ]
      },{...}
    ]
  }
}
   */
  Future<Map<String, dynamic>> getCharacters(String id) async {
    return await _fetchData("/character/list/$id");
  }
  /* Stream Info
    {
  "success": true,
  "results": {
    "streamingLink": [
      {
            "id":number,
            "type": "sub",
            "link": {
              "file":string,
              "type":string,
            },
            "tracks": [
              {
                "file": string,
                "label": string,
                "kind": string,
                "default": boolean
              },{...}
            ],
            "intro": [Object],
            "outro": [Object],
            "server":string
      }
    ],
    "servers": [
      {
        "type":string,
        "data_id": number,
        "server_id": number,
        "server_name": string
      },
      {...}
      ]
    }
  }
  */
  Future<Map<String, dynamic>> getStream(String id, String server, String type) async {
    return await _fetchData("/stream?id=$id&server=$server&type=$type");
  }
  /*

  {
    "success": true,
    "results": [
      {
        "type": string,
        "data_id": number,
        "server_id": number,
        "serverName": string
      },
      {...},
    ]
  }
  */
  Future<Map<String, dynamic>> getServers(String id) async {
    return await _fetchData("/servers/$id");
  }
}