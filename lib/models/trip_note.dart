class TripNote {
  TripNote({
    required this.id,
    required this.tripId,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int tripId;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TripNote.fromMap(Map<String, Object?> map) {
    return TripNote(
      id: map['id'] as int,
      tripId: map['trip_id'] as int,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
