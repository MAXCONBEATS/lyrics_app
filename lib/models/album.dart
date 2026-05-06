class Album {
  final int? id;
  final String title;
  final DateTime createdAt;

  Album({
    this.id,
    required this.title,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toIso8601String(),
      };

  factory Album.fromMap(Map<String, dynamic> map) => Album(
        id: map['id'],
        title: map['title'],
        createdAt: DateTime.parse(map['created_at']),
      );
}