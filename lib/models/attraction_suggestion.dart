class AttractionSuggestion {
  final int? id;
  final int tripId;
  final String name;
  final String? description;
  final double? lat;
  final double? lng;
  final String? type;
  final String? rating;
  final String? url;

  AttractionSuggestion({
    this.id,
    required this.tripId,
    required this.name,
    this.description,
    this.lat,
    this.lng,
    this.type,
    this.rating,
    this.url,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'description': description,
      'lat': lat,
      'lng': lng,
      'type': type,
      'rating': rating,
      'url': url,
    };
  }

  factory AttractionSuggestion.fromMap(Map<String, Object?> map) {
    return AttractionSuggestion(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      lat: map['lat'] as double?,
      lng: map['lng'] as double?,
      type: map['type'] as String?,
      rating: map['rating'] as String?,
      url: map['url'] as String?,
    );
  }
}
