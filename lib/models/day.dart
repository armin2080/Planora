class Day {
  Day({
    required this.id,
    required this.tripId,
    required this.name,
    required this.dayOrder,
    required this.createdAt,
  });

  final int id;
  final int tripId;
  final String name;
  final int dayOrder;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'day_order': dayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Day.fromMap(Map<String, Object?> map) {
    return Day(
      id: map['id'] as int,
      tripId: map['trip_id'] as int,
      name: map['name'] as String,
      dayOrder: map['day_order'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
