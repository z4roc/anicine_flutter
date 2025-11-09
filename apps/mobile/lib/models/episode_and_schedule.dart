class EpisodeItem {
  final int episodeNo;
  final String id;
  final String? dataId;
  final String? jname;
  final String title;
  final String? japaneseTitle;

  EpisodeItem({
    required this.episodeNo,
    required this.id,
    this.dataId,
    this.jname,
    required this.title,
    this.japaneseTitle,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      episodeNo: json['episode_no'] != null 
          ? int.tryParse(json['episode_no'].toString()) ?? 0 
          : 0,
      id: json['id']?.toString() ?? '',
      dataId: json['data_id']?.toString(),
      jname: json['jname']?.toString(),
      title: json['title']?.toString() ?? 'Episode ${json['episode_no']}',
      japaneseTitle: json['japanese_title']?.toString(),
    );
  }
}

class ScheduleItem {
  final String id;
  final String? dataId;
  final String title;
  final String? japaneseTitle;
  final String? releaseDate;
  final String? time;
  final int? episodeNo;

  ScheduleItem({
    required this.id,
    this.dataId,
    required this.title,
    this.japaneseTitle,
    this.releaseDate,
    this.time,
    this.episodeNo,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id']?.toString() ?? '',
      dataId: json['data_id']?.toString(),
      title: json['title']?.toString() ?? 'Unknown',
      japaneseTitle: json['japanese_title']?.toString(),
      releaseDate: json['releaseDate']?.toString(),
      time: json['time']?.toString(),
      episodeNo: json['episode_no'] != null 
          ? int.tryParse(json['episode_no'].toString()) 
          : null,
    );
  }
}

class VoiceActor {
  final String id;
  final String? poster;
  final String name;

  VoiceActor({
    required this.id,
    this.poster,
    required this.name,
  });

  factory VoiceActor.fromJson(Map<String, dynamic> json) {
    return VoiceActor(
      id: json['id']?.toString() ?? '',
      poster: json['poster']?.toString(),
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}

class Character {
  final String id;
  final String? poster;
  final String name;
  final String? cast;

  Character({
    required this.id,
    this.poster,
    required this.name,
    this.cast,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id']?.toString() ?? '',
      poster: json['poster']?.toString(),
      name: json['name']?.toString() ?? 'Unknown',
      cast: json['cast']?.toString(),
    );
  }
}

class CharacterWithVoiceActors {
  final Character character;
  final List<VoiceActor> voiceActors;

  CharacterWithVoiceActors({
    required this.character,
    required this.voiceActors,
  });

  factory CharacterWithVoiceActors.fromJson(Map<String, dynamic> json) {
    return CharacterWithVoiceActors(
      character: Character.fromJson(json['character']),
      voiceActors: (json['voiceActors'] as List<dynamic>?)
          ?.map((e) => VoiceActor.fromJson(e))
          .toList() ?? [],
    );
  }
}
