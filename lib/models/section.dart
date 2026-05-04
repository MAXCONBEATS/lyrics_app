enum SectionType {
  intro,
  verse,
  preChorus,
  chorus,
  postChorus,
  bridge,
  outro,
  custom,
}

class SongSection {
  final int? id;
  final int? songId;
  final SectionType type;
  final String text;
  final String? customLabel;
  final int sortOrder;

  SongSection({
    this.id,
    this.songId,
    required this.type,
    required this.text,
    this.customLabel,
    required this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'customLabel': customLabel,
        'sortOrder': sortOrder,
      };

  factory SongSection.fromJson(Map<String, dynamic> json) => SongSection(
        type: SectionType.values.firstWhere((e) => e.name == json['type']),
        text: json['text'],
        customLabel: json['customLabel'],
        sortOrder: json['sortOrder'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'song_id': songId,
        'type': type.name,
        'text': text,
        'custom_label': customLabel,
        'sort_order': sortOrder,
      };

  factory SongSection.fromMap(Map<String, dynamic> map) => SongSection(
        id: map['id'],
        songId: map['song_id'],
        type: SectionType.values.firstWhere((e) => e.name == map['type']),
        text: map['text'],
        customLabel: map['custom_label'],
        sortOrder: map['sort_order'],
      );
}