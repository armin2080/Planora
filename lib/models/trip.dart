class Trip {
  Trip({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.coverPhotoPath,
    required this.createdAt,
  });

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? coverPhotoPath;
  final DateTime createdAt;

  Trip copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? coverPhotoPath,
    bool clearCoverPhotoPath = false,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverPhotoPath:
          clearCoverPhotoPath ? null : (coverPhotoPath ?? this.coverPhotoPath),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'cover_photo_path': coverPhotoPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, Object?> map) {
    return Trip(
      id: map['id'] as int,
      name: map['name'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      coverPhotoPath: map['cover_photo_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
