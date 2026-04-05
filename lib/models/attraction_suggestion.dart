class AttractionSuggestion {
  final int? id;
  final int tripId;
  final String name;
  final String? description;
  final double? lat;
  final double? lng;
  final String? type;
  final String? rating;
  final double? score;
  final String? imageUrl;
  final String? sourceUrl;
  final String? categoryKey;
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
    this.score,
    this.imageUrl,
    this.sourceUrl,
    this.categoryKey,
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
      'score': score,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'category_key': categoryKey,
      'url': url,
    };
  }

  factory AttractionSuggestion.fromMap(Map<String, Object?> map) {
    final latValue = map['lat'];
    final lngValue = map['lng'];

    return AttractionSuggestion(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      lat: latValue is num ? latValue.toDouble() : null,
      lng: lngValue is num ? lngValue.toDouble() : null,
      type: map['type'] as String?,
      rating: map['rating'] as String?,
      score: _doubleFromValue(map['score']),
      imageUrl: map['image_url'] as String?,
      sourceUrl: map['source_url'] as String?,
      categoryKey: map['category_key'] as String?,
      url: map['url'] as String?,
    );
  }

  String get category {
    final explicitCategory = _normalizeCategoryKey(categoryKey);
    if (explicitCategory != null) {
      return explicitCategory;
    }

    final normalizedType = (type ?? '').trim().toLowerCase();

    final derivedCategory = _categoryFromType(normalizedType);
    if (derivedCategory != null) {
      return derivedCategory;
    }

    return 'other';
  }

  static const categoryOrder = [
    'attractions',
    'museums',
    'viewpoints',
    'landmarks',
    'tours',
    'outdoor_activities',
    'nature_parks',
    'food_drink',
    'shopping',
    'nightlife',
    'entertainment',
    'wellness',
    'family_fun',
    'zoos_aquariums',
    'water_amusement_parks',
    'classes_workshops',
    'transportation',
    'traveler_resources',
    'other',
  ];

  static String categoryLabel(String category) {
    switch (category) {
      case 'attractions':
        return 'Attractions';
      case 'museums':
        return 'Museums';
      case 'viewpoints':
        return 'Viewpoints';
      case 'landmarks':
        return 'Sights & Landmarks';
      case 'tours':
        return 'Tours';
      case 'outdoor_activities':
        return 'Outdoor Activities';
      case 'nature_parks':
        return 'Nature & Parks';
      case 'food_drink':
        return 'Food & Drink';
      case 'shopping':
        return 'Shopping';
      case 'nightlife':
        return 'Nightlife';
      case 'entertainment':
        return 'Concerts & Shows';
      case 'wellness':
        return 'Spas & Wellness';
      case 'family_fun':
        return 'Fun & Games';
      case 'zoos_aquariums':
        return 'Zoos & Aquariums';
      case 'water_amusement_parks':
        return 'Water & Amusement Parks';
      case 'classes_workshops':
        return 'Classes & Workshops';
      case 'transportation':
        return 'Transportation';
      case 'traveler_resources':
        return 'Traveler Resources';
      default:
        return 'Other';
    }
  }

  static double? _doubleFromValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static String? _normalizeCategoryKey(String? categoryKey) {
    if (categoryKey == null) {
      return null;
    }

    final normalized = categoryKey.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized.isEmpty) {
      return null;
    }

    if (categoryOrder.contains(normalized)) {
      return normalized;
    }

    if (normalized.contains('museum')) return 'museums';
    if (normalized.contains('view')) return 'viewpoints';
    if (normalized.contains('landmark') || normalized.contains('historic')) {
      return 'landmarks';
    }
    if (normalized.contains('tour')) return 'tours';
    if (normalized.contains('outdoor') || normalized.contains('activity')) {
      return 'outdoor_activities';
    }
    if (normalized.contains('park') || normalized.contains('nature')) {
      return 'nature_parks';
    }
    if (normalized.contains('food') || normalized.contains('drink')) {
      return 'food_drink';
    }
    if (normalized.contains('shop')) return 'shopping';
    if (normalized.contains('night')) return 'nightlife';
    if (normalized.contains('show') || normalized.contains('concert')) {
      return 'entertainment';
    }
    if (normalized.contains('spa') || normalized.contains('wellness')) {
      return 'wellness';
    }
    if (normalized.contains('family') || normalized.contains('games')) {
      return 'family_fun';
    }
    if (normalized.contains('zoo') || normalized.contains('aquarium')) {
      return 'zoos_aquariums';
    }
    if (normalized.contains('water') || normalized.contains('amusement')) {
      return 'water_amusement_parks';
    }
    if (normalized.contains('class') || normalized.contains('workshop')) {
      return 'classes_workshops';
    }
    if (normalized.contains('transport')) return 'transportation';
    if (normalized.contains('resource')) return 'traveler_resources';
    if (normalized.contains('attraction')) return 'attractions';

    return null;
  }

  static String? _categoryFromType(String normalizedType) {
    if (normalizedType.isEmpty) {
      return null;
    }

    if (_museumTypes.contains(normalizedType)) {
      return 'museums';
    }
    if (_viewpointTypes.contains(normalizedType)) {
      return 'viewpoints';
    }
    if (_landmarkTypes.contains(normalizedType)) {
      return 'landmarks';
    }
    if (_tourTypes.contains(normalizedType)) {
      return 'tours';
    }
    if (_outdoorTypes.contains(normalizedType)) {
      return 'outdoor_activities';
    }
    if (_natureTypes.contains(normalizedType)) {
      return 'nature_parks';
    }
    if (_foodTypes.contains(normalizedType)) {
      return 'food_drink';
    }
    if (_shoppingTypes.contains(normalizedType)) {
      return 'shopping';
    }
    if (_nightlifeTypes.contains(normalizedType)) {
      return 'nightlife';
    }
    if (_entertainmentTypes.contains(normalizedType)) {
      return 'entertainment';
    }
    if (_wellnessTypes.contains(normalizedType)) {
      return 'wellness';
    }
    if (_familyTypes.contains(normalizedType)) {
      return 'family_fun';
    }
    if (_zooTypes.contains(normalizedType)) {
      return 'zoos_aquariums';
    }
    if (_waterParkTypes.contains(normalizedType)) {
      return 'water_amusement_parks';
    }
    if (_classTypes.contains(normalizedType)) {
      return 'classes_workshops';
    }
    if (_transportTypes.contains(normalizedType)) {
      return 'transportation';
    }
    if (_resourceTypes.contains(normalizedType)) {
      return 'traveler_resources';
    }
    if (_attractionTypes.contains(normalizedType)) {
      return 'attractions';
    }

    return null;
  }

  static const Set<String> _attractionTypes = {
    'attraction',
    'site',
    'place',
    'point_of_interest',
  };

  static const Set<String> _museumTypes = {
    'museum',
    'gallery',
    'history_museum',
    'art_museum',
    'science_museum',
  };

  static const Set<String> _viewpointTypes = {
    'viewpoint',
    'scenic_viewpoint',
    'lookout',
    'observation_deck',
  };

  static const Set<String> _landmarkTypes = {
    'historic',
    'monument',
    'castle',
    'ruins',
    'memorial',
    'church',
    'cathedral',
    'landmark',
    'artwork',
  };

  static const Set<String> _tourTypes = {
    'tour',
    'city_tour',
    'boat_tour',
    'sightseeing',
    'guided_tour',
    'excursion',
  };

  static const Set<String> _outdoorTypes = {
    'park',
    'theme_park',
    'sports_centre',
    'stadium',
    'leisure',
    'cinema',
    'theatre',
    'beach_resort',
    'adventure',
  };

  static const Set<String> _natureTypes = {
    'nature_reserve',
    'park',
    'garden',
    'forest',
    'nature_park',
  };

  static const Set<String> _foodTypes = {
    'restaurant',
    'cafe',
    'fast_food',
    'bar',
    'pub',
    'food_court',
    'winery',
    'brewery',
  };

  static const Set<String> _shoppingTypes = {
    'shop',
    'mall',
    'market',
    'shopping',
    'boutique',
  };

  static const Set<String> _nightlifeTypes = {
    'nightclub',
    'bar',
    'pub',
    'lounge',
    'club',
  };

  static const Set<String> _entertainmentTypes = {
    'theatre',
    'cinema',
    'opera',
    'concert_hall',
    'amphitheatre',
  };

  static const Set<String> _wellnessTypes = {
    'spa',
    'wellness',
    'massage',
    'sauna',
    'thermal',
  };

  static const Set<String> _familyTypes = {
    'playground',
    'arcade',
    'game_center',
    'escape_room',
    'family_fun',
  };

  static const Set<String> _zooTypes = {
    'zoo',
    'aquarium',
    'information',
    'visitor_centre',
    'yes',
  };

  static const Set<String> _waterParkTypes = {
    'water_park',
    'amusement_park',
    'theme_park',
    'aquapark',
  };

  static const Set<String> _classTypes = {
    'class',
    'workshop',
    'lesson',
    'course',
  };

  static const Set<String> _transportTypes = {
    'ferry',
    'station',
    'transit',
    'transport',
    'bus_station',
    'train_station',
  };

  static const Set<String> _resourceTypes = {
    'visitor_centre',
    'information',
    'tourist_information',
    'travel_agency',
  };
}
