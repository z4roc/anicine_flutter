class TvInfo {
  final String? showType;
  final String? duration;
  final String? releaseDate;
  final String? quality;

  TvInfo({
    this.showType,
    this.duration,
    this.releaseDate,
    this.quality,
  });

  factory TvInfo.fromJson(Map<String, dynamic> json) {
    return TvInfo(
      showType: json['showType']?.toString(),
      duration: json['duration']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
      quality: json['quality']?.toString(),
    );
  }
}

class Anime {
  final String id;
  final String? dataId;
  final String name;
  final String? japaneseTitle;
  final String? poster;
  final String? description;
  final int? number;
  final int? totalEpisodes;
  final List<String>? genres;
  final TvInfo? tvInfo;
  final String? type;
  final String? status;
  final String? releaseDate;

  Anime({
    required this.id,
    this.dataId,
    required this.name,
    this.japaneseTitle,
    this.poster,
    this.description,
    this.number,
    this.totalEpisodes,
    this.genres,
    this.tvInfo,
    this.type,
    this.status,
    this.releaseDate,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      id: json['id']?.toString() ?? '',
      dataId: json['data_id']?.toString(),
      name: json['title']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      japaneseTitle: json['japanese_title']?.toString(),
      poster: json['poster']?.toString() ?? json['image']?.toString(),
      description: json['description']?.toString(),
      number: json['number'] != null ? int.tryParse(json['number'].toString()) : null,
      totalEpisodes: json['totalEpisodes'] != null 
          ? int.tryParse(json['totalEpisodes'].toString())
          : json['episodes']?.length,
      genres: json['genres'] != null 
          ? (json['genres'] as List).map((e) => e.toString()).toList()
          : null,
      tvInfo: json['tvInfo'] != null 
          ? TvInfo.fromJson(json['tvInfo']) 
          : null,
      type: json['type']?.toString() ?? json['tvInfo']?['showType']?.toString(),
      status: json['status']?.toString(),
      releaseDate: json['releaseDate']?.toString() ?? json['tvInfo']?['releaseDate']?.toString(),
    );
  }
}

class Episode {
  final String id;
  final int number;
  final String? title;
  final String? thumbnail;

  Episode({
    required this.id,
    required this.number,
    this.title,
    this.thumbnail,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id']?.toString() ?? json['episodeId']?.toString() ?? '',
      number: json['number'] != null 
          ? int.tryParse(json['number'].toString()) ?? 0
          : (json['episodeNumber'] != null 
              ? int.tryParse(json['episodeNumber'].toString()) ?? 0 
              : 0),
      title: json['title']?.toString(),
      thumbnail: json['thumbnail']?.toString() ?? json['image']?.toString(),
    );
  }
}
