class TripDocument {
  TripDocument({
    required this.id,
    required this.tripId,
    required this.filePath,
    required this.type,
    required this.createdAt,
  });

  final int id;
  final int tripId;
  final String filePath;
  final String type;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'file_path': filePath,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TripDocument.fromMap(Map<String, Object?> map) {
    return TripDocument(
      id: map['id'] as int,
      tripId: map['trip_id'] as int,
      filePath: map['file_path'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
