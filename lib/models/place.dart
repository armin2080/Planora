class Place {
  Place({
    required this.id,
    required this.tripId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.note,
    this.googleMapsUrl,
    this.tripadvisorUrl,
    this.category,
    this.photoUrl,
    required this.createdAt,
  });

  final int id;
  final int tripId;
  final String name;
  final double latitude;
  final double longitude;
  final String? note;
  final String? googleMapsUrl;
  final String? tripadvisorUrl;
  final String? category;
  final String? photoUrl;
  final DateTime createdAt;

  Place copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? note,
    String? googleMapsUrl,
    String? tripadvisorUrl,
    String? category,
    String? photoUrl,
  }) {
    return Place(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      note: note ?? this.note,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      tripadvisorUrl: tripadvisorUrl ?? this.tripadvisorUrl,
      category: category ?? this.category,
      photoUrl: photoUrl ?? this.photoUrl,
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
      'google_maps_url': googleMapsUrl,
      'tripadvisor_url': tripadvisorUrl,
      'category': category,
      'photo_url': photoUrl,
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
      googleMapsUrl: map['google_maps_url'] as String?,
      tripadvisorUrl: map['tripadvisor_url'] as String?,
      category: map['category'] as String?,
      photoUrl: map['photo_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
