class AnimeInfo {
  final String? overview;
  final String? japanese;
  final String? synonyms;
  final String? aired;
  final String? premiered;
  final String? duration;
  final String? status;
  final String? malScore;
  final List<String>? genres;
  final String? studios;
  final List<String>? producers;

  AnimeInfo({
    this.overview,
    this.japanese,
    this.synonyms,
    this.aired,
    this.premiered,
    this.duration,
    this.status,
    this.malScore,
    this.genres,
    this.studios,
    this.producers,
  });

  factory AnimeInfo.fromJson(Map<String, dynamic> json) {
    return AnimeInfo(
      overview: json['Overview']?.toString(),
      japanese: json['Japanese']?.toString(),
      synonyms: json['Synonyms']?.toString(),
      aired: json['Aired']?.toString(),
      premiered: json['Premiered']?.toString(),
      duration: json['Duration']?.toString(),
      status: json['Status']?.toString(),
      malScore: json['MAL Score']?.toString(),
      genres: json['Genres'] != null 
          ? (json['Genres'] is List 
              ? (json['Genres'] as List).map((e) => e.toString()).toList()
              : [json['Genres'].toString()])
          : null,
      studios: json['Studios']?.toString(),
      producers: json['Producers'] != null 
          ? (json['Producers'] is List 
              ? (json['Producers'] as List).map((e) => e.toString()).toList()
              : [json['Producers'].toString()])
          : null,
    );
  }
}

class AnimeDetails {
  final bool? adultContent;
  final String id;
  final String? dataId;
  final String title;
  final String? japaneseTitle;
  final String? poster;
  final String? showType;
  final AnimeInfo? animeInfo;

  AnimeDetails({
    this.adultContent,
    required this.id,
    this.dataId,
    required this.title,
    this.japaneseTitle,
    this.poster,
    this.showType,
    this.animeInfo,
  });

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    return AnimeDetails(
      adultContent: json['adultContent'] is bool 
          ? json['adultContent']
          : (json['adultContent']?.toString().toLowerCase() == 'true'),
      id: json['id']?.toString() ?? '',
      dataId: json['data_id']?.toString(),
      title: json['title']?.toString() ?? 'Unknown',
      japaneseTitle: json['japanese_title']?.toString(),
      poster: json['poster']?.toString(),
      showType: json['showType']?.toString(),
      animeInfo: json['animeInfo'] != null 
          ? AnimeInfo.fromJson(json['animeInfo'])
          : null,
    );
  }
}

class Season {
  final String id;
  final String? dataNumber;
  final String? dataId;
  final String? season;
  final String title;
  final String? japaneseTitle;
  final String? seasonPoster;

  Season({
    required this.id,
    this.dataNumber,
    this.dataId,
    this.season,
    required this.title,
    this.japaneseTitle,
    this.seasonPoster,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id']?.toString() ?? '',
      dataNumber: json['data_number']?.toString(),
      dataId: json['data_id']?.toString(),
      season: json['season']?.toString(),
      title: json['title']?.toString() ?? 'Unknown',
      japaneseTitle: json['japanese_title']?.toString(),
      seasonPoster: json['season_poster']?.toString(),
    );
  }
}
