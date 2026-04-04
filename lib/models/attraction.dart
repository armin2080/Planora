class AttractionSuggestion {
  final String id;
  final String name;
  final String? description;
  final double? lat;
  final double? lng;
  final String? category;
  final double? rating;

  AttractionSuggestion({
    required this.id,
    required this.name,
    this.description,
    this.lat,
    this.lng,
    this.category,
    this.rating,
  });

  factory AttractionSuggestion.fromJson(Map<String, dynamic> json) {
    return AttractionSuggestion(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      lat: json['latitude'] ?? json['lat'],
      lng: json['longitude'] ?? json['lng'],
      category: json['category'] ?? json['category_name'],
      rating: json['rating']?.toDouble(),
    );
  }
}
