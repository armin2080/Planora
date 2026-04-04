class Place {
  Place({
    required this.id,
    required this.tripId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int tripId;
  final String name;
  final double latitude;
  final double longitude;
  final String? note;
  final DateTime createdAt;

  Place copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? note,
  }) {
    return Place(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'lat': latitude,
      'lng': longitude,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Place.fromMap(Map<String, Object?> map) {
    return Place(
      id: map['id'] as int,
      tripId: map['trip_id'] as int,
      name: map['name'] as String,
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
