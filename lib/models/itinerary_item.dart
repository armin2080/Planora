class ItineraryItem {
  ItineraryItem({
    required this.id,
    required this.tripId,
    required this.dayId,
    required this.placeId,
    required this.position,
    required this.placeName,
    required this.createdAt,
  });

  final int id;
  final int tripId;
  final int dayId;
  final int placeId;
  final int position;
  final String placeName;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'day_id': dayId,
      'place_id': placeId,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItineraryItem.fromMap(Map<String, Object?> map) {
    return ItineraryItem(
      id: map['id'] as int,
      tripId: map['trip_id'] as int,
      dayId: map['day_id'] as int,
      placeId: map['place_id'] as int,
      position: map['position'] as int,
      placeName: (map['place_name'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
