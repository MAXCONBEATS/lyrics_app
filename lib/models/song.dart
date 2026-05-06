import 'section.dart';
class Song {
  final int? id;
  int? albumId;
  final String title;
  final List<SongSection> sections;   // оставляем для обратной совместимости
  final String? rawText;              // новое поле – весь текст с метками
  final DateTime createdAt;
  final DateTime updatedAt;

  Song({
    this.id,
    this.albumId,
    required this.title,
    required this.sections,
    this.rawText,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'sections': sections.map((s) => s.toJson()).toList(),
        'rawText': rawText,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Song.fromJson(int? albumId, Map<String, dynamic> json) => Song(
        albumId: albumId,
        title: json['title'],
        sections: (json['sections'] as List)
            .map((s) => SongSection.fromJson(s))
            .toList(),
        rawText: json['rawText'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'album_id': albumId,
        'title': title,
        'raw_text': rawText ?? '',
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Song.fromMap(Map<String, dynamic> map, {List<SongSection>? sections}) => Song(
        id: map['id'],
        albumId: map['album_id'],
        title: map['title'],
        sections: sections ?? [],
        rawText: map['raw_text'] is String ? map['raw_text'] : null,
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
      );
}