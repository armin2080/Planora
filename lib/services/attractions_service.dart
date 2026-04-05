import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/attraction_suggestion.dart';

class AttractionsService {
  static const _timeout = Duration(seconds: 15);
  static const _userAgent = 'Planora/1.0 (contact: planora-app)';
  static const _tripadvisorBaseUrl = 'api.content.tripadvisor.com';
  static const _tripadvisorApiKey =
      String.fromEnvironment('TRIPADVISOR_API_KEY');
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<List<AttractionSuggestion>> fetchAttractions(
      String cityName, int tripId) async {
    developer.log('[AttractionsService] Fetching for: $cityName');
    final isOnline = await hasInternetConnection();
    if (!isOnline) return [];

    try {
      final coords = await _geocodeCity(cityName);
      if (coords == null) return [];

      final tripadvisorAttractions = await _fetchTripadvisorAttractions(
          coords['lat'] as double, coords['lng'] as double, tripId);
      if (tripadvisorAttractions.isNotEmpty) {
        return tripadvisorAttractions;
      }

      return await _fetchNearbyAttractions(
        coords['lat'] as double,
        coords['lng'] as double,
        cityName,
        tripId,
      );
    } catch (e) {
      developer.log('[AttractionsService] Error: $e');
      return [];
    }
  }

  Future<List<AttractionSuggestion>> _fetchTripadvisorAttractions(
    double lat,
    double lng,
    int tripId,
  ) async {
    if (_tripadvisorApiKey.isEmpty) {
      return [];
    }

    try {
      final nearby = await _tripadvisorJson(
        Uri.https(
          _tripadvisorBaseUrl,
          '/api/v1/location/nearby_search',
          {
            'key': _tripadvisorApiKey,
            'category': 'attractions',
            'latLong': '$lat,$lng',
            'radius': '25000',
            'radiusUnit': 'm',
            'language': 'en',
          },
        ),
      );

      final locations = _extractTripadvisorLocations(nearby);
      final attractions = <AttractionSuggestion>[];

      for (final location in locations.take(10)) {
        final locationData = location;
        final locationId = _extractLocationId(location);
        if (locationId == null) {
          continue;
        }

        final details = await _tripadvisorJson(
          Uri.https(
            _tripadvisorBaseUrl,
            '/api/v1/location/$locationId/details',
            {
              'key': _tripadvisorApiKey,
              'language': 'en',
              'currency': 'USD',
            },
          ),
        );

        final photos = await _tripadvisorJson(
          Uri.https(
            _tripadvisorBaseUrl,
            '/api/v1/location/$locationId/photos',
            {
              'key': _tripadvisorApiKey,
              'language': 'en',
              'limit': '1',
              'source': 'Expert,Management,Traveler',
            },
          ),
        );

        final detailsData = details ?? <String, dynamic>{};
        final photosData = photos ?? <String, dynamic>{};

        final categoryKey = _tripadvisorCategoryKey(detailsData) ??
            _tripadvisorCategoryKey(locationData) ??
            'attractions';
        final score =
            _tripadvisorRating(detailsData) ?? _tripadvisorRating(locationData);
        final imageUrl = _tripadvisorPhotoUrl(photosData) ??
            _tripadvisorPhotoUrl(detailsData) ??
            _tripadvisorPhotoUrl(locationData);
        final name = _tripadvisorString(detailsData, ['name']) ??
            _tripadvisorString(locationData, ['name']);

        if (name == null || name.trim().isEmpty) {
          continue;
        }

        attractions.add(
          AttractionSuggestion(
            tripId: tripId,
            name: name.trim(),
            description: _tripadvisorString(detailsData, ['description']) ??
                _tripadvisorString(locationData, ['description']),
            lat: _tripadvisorDouble(detailsData, ['latitude', 'lat']) ??
                _tripadvisorDouble(locationData, ['latitude', 'lat']),
            lng: _tripadvisorDouble(detailsData, ['longitude', 'lng']) ??
                _tripadvisorDouble(locationData, ['longitude', 'lng']),
            type: _tripadvisorString(detailsData, [
                  'subcategory',
                  'category',
                  'group',
                  'type',
                ]) ??
                _tripadvisorString(locationData, [
                  'subcategory',
                  'category',
                  'group',
                  'type',
                ]),
            rating: score?.toStringAsFixed(1),
            score: score,
            imageUrl: imageUrl,
            sourceUrl: _tripadvisorString(detailsData, [
                  'web_url',
                  'website',
                  'url',
                ]) ??
                _tripadvisorString(locationData, [
                  'web_url',
                  'website',
                  'url',
                ]),
            categoryKey: categoryKey,
            url: _tripadvisorString(detailsData, [
                  'web_url',
                  'website',
                  'url',
                ]) ??
                _tripadvisorString(locationData, [
                  'web_url',
                  'website',
                  'url',
                ]),
          ),
        );
      }

      attractions.sort((left, right) {
        final categoryComparison = left.category.compareTo(right.category);
        if (categoryComparison != 0) {
          return categoryComparison;
        }

        final leftScore = left.score ?? -1;
        final rightScore = right.score ?? -1;
        final scoreComparison = rightScore.compareTo(leftScore);
        if (scoreComparison != 0) {
          return scoreComparison;
        }

        return left.name.compareTo(right.name);
      });

      return attractions;
    } catch (e) {
      developer.log('[AttractionsService] Tripadvisor error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _geocodeCity(String cityName) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(cityName)}&format=json&limit=1';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List?;
        if (json != null && json.isNotEmpty) {
          final place = json.first as Map<String, dynamic>;
          return {
            'lat': double.parse(place['lat'] as String),
            'lng': double.parse(place['lon'] as String),
          };
        }
      }
      return null;
    } catch (e) {
      developer.log('[AttractionsService] Geocode error: $e');
      return null;
    }
  }

  Future<List<AttractionSuggestion>> _fetchNearbyAttractions(
    double lat,
    double lng,
    String cityName,
    int tripId,
  ) async {
    final query = '''
[out:json][timeout:20];
(
  node["tourism"~"^(attraction|museum|gallery|viewpoint|theme_park|zoo|aquarium)\$"](around:25000,$lat,$lng);
  node["historic"](around:25000,$lat,$lng);
  node["leisure"~"^(park|sports_centre|stadium|nature_reserve|garden)\$"](around:25000,$lat,$lng);
  node["amenity"~"^(theatre|cinema|arts_centre|restaurant|cafe|fast_food|bar|pub)\$"](around:25000,$lat,$lng);
  node["shop"](around:25000,$lat,$lng);
);
out body;
''';
    final url =
        'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(_timeout);
      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = json['elements'] as List? ?? [];
      final attractions = <AttractionSuggestion>[];
      final perCategoryCount = <String, int>{};
      const maxPerCategory = 6;

      for (final el in elements) {
        final tags = (el['tags'] ?? {}) as Map<String, dynamic>;
        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue;

        final type = _getType(tags);
        final category = _categoryFromType(type);
        final currentCount = perCategoryCount[category] ?? 0;
        if (currentCount >= maxPerCategory) {
          continue;
        }

        final latValue = el['lat'];
        final lonValue = el['lon'];

        attractions.add(AttractionSuggestion(
          tripId: tripId,
          name: name,
          lat: latValue is num ? latValue.toDouble() : null,
          lng: lonValue is num ? lonValue.toDouble() : null,
          type: type,
          description: tags['description'] as String?,
          rating: _osmRating(tags),
          score: _osmScore(tags),
          imageUrl: _imageUrlFromTags(tags),
          sourceUrl: (tags['website'] ?? tags['url'])?.toString(),
          categoryKey: category,
          url: (tags['website'] ?? tags['url'])?.toString(),
        ));

        perCategoryCount[category] = currentCount + 1;
        if (attractions.length >= 24) {
          break;
        }
      }
      return attractions;
    } catch (e) {
      developer.log('[AttractionsService] API error: $e');
      return [];
    }
  }

  String _getType(Map<String, dynamic> tags) {
    return (tags['tourism'] ??
        tags['amenity'] ??
        tags['leisure'] ??
        tags['shop'] ??
        tags['historic'] ??
        'place') as String;
  }

  String _categoryFromType(String type) {
    final normalized = type.trim().toLowerCase();
    if ({'museum', 'gallery'}.contains(normalized)) return 'museums';
    if ({'viewpoint', 'lookout', 'observation_deck'}.contains(normalized)) {
      return 'viewpoints';
    }
    if ({'historic', 'monument', 'castle', 'ruins', 'memorial', 'church'}
        .contains(normalized)) {
      return 'landmarks';
    }
    if ({'tour', 'guided_tour', 'excursion', 'sightseeing'}
        .contains(normalized)) {
      return 'tours';
    }
    if ({'park', 'theme_park', 'sports_centre', 'stadium', 'adventure'}
        .contains(normalized)) {
      return 'outdoor_activities';
    }
    if ({'nature_reserve', 'garden', 'forest', 'nature_park'}
        .contains(normalized)) {
      return 'nature_parks';
    }
    if ({
      'restaurant',
      'cafe',
      'fast_food',
      'bar',
      'pub',
      'food_court',
      'brewery',
      'winery'
    }.contains(normalized)) {
      return 'food_drink';
    }
    if ({'shop', 'mall', 'market', 'shopping', 'boutique'}
        .contains(normalized)) {
      return 'shopping';
    }
    if ({'nightclub', 'lounge', 'club', 'bar', 'pub'}.contains(normalized)) {
      return 'nightlife';
    }
    if ({'theatre', 'cinema', 'opera', 'concert_hall', 'amphitheatre'}
        .contains(normalized)) {
      return 'entertainment';
    }
    if ({'spa', 'wellness', 'massage', 'sauna', 'thermal'}
        .contains(normalized)) {
      return 'wellness';
    }
    if ({'playground', 'arcade', 'game_center', 'escape_room'}
        .contains(normalized)) {
      return 'family_fun';
    }
    if ({'zoo', 'aquarium'}.contains(normalized)) return 'zoos_aquariums';
    if ({'water_park', 'amusement_park', 'aquapark'}.contains(normalized)) {
      return 'water_amusement_parks';
    }
    if ({'class', 'workshop', 'lesson', 'course'}.contains(normalized)) {
      return 'classes_workshops';
    }
    if ({
      'ferry',
      'station',
      'transit',
      'transport',
      'bus_station',
      'train_station'
    }.contains(normalized)) {
      return 'transportation';
    }
    if ({
      'visitor_centre',
      'information',
      'tourist_information',
      'travel_agency'
    }.contains(normalized)) {
      return 'traveler_resources';
    }
    if ({'attraction', 'point_of_interest', 'place', 'site'}
        .contains(normalized)) {
      return 'attractions';
    }
    return 'other';
  }

  Future<Map<String, dynamic>?> _tripadvisorJson(Uri uri) async {
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    ).timeout(_timeout);

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  List<Map<String, dynamic>> _extractTripadvisorLocations(
    Map<String, dynamic>? payload,
  ) {
    if (payload == null) {
      return [];
    }

    final candidates = [
      payload['data'],
      payload['results'],
      payload['locations'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList(growable: false);
      }
    }

    return [];
  }

  int? _extractLocationId(Map<String, dynamic> payload) {
    final value = payload['location_id'] ??
        payload['locationId'] ??
        payload['id'] ??
        payload['location_id_string'];

    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String? _tripadvisorCategoryKey(Map<String, dynamic> payload) {
    final fields = [
      payload['subcategory'],
      payload['subcategories'],
      payload['category'],
      payload['category_name'],
      payload['group'],
      payload['group_name'],
      payload['type'],
    ];

    for (final field in fields) {
      final normalized = _normalizeTripadvisorCategory(field);
      if (normalized != null) {
        return normalized;
      }
    }

    return null;
  }

  String? _normalizeTripadvisorCategory(Object? value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) {
      return null;
    }

    if (text.contains('museum')) return 'museums';
    if (text.contains('view') || text.contains('lookout')) return 'viewpoints';
    if (text.contains('landmark') || text.contains('historic')) {
      return 'landmarks';
    }
    if (text.contains('tour')) return 'tours';
    if (text.contains('outdoor') || text.contains('activity')) {
      return 'outdoor_activities';
    }
    if (text.contains('nature') || text.contains('park')) return 'nature_parks';
    if (text.contains('food') ||
        text.contains('drink') ||
        text.contains('restaurant')) {
      return 'food_drink';
    }
    if (text.contains('shop')) return 'shopping';
    if (text.contains('night')) return 'nightlife';
    if (text.contains('show') ||
        text.contains('concert') ||
        text.contains('theater')) {
      return 'entertainment';
    }
    if (text.contains('spa') || text.contains('wellness')) return 'wellness';
    if (text.contains('family') || text.contains('game')) return 'family_fun';
    if (text.contains('zoo') || text.contains('aquarium')) {
      return 'zoos_aquariums';
    }
    if (text.contains('water') || text.contains('amusement')) {
      return 'water_amusement_parks';
    }
    if (text.contains('class') || text.contains('workshop')) {
      return 'classes_workshops';
    }
    if (text.contains('transport')) return 'transportation';
    if (text.contains('resource') || text.contains('information')) {
      return 'traveler_resources';
    }
    if (text.contains('attraction')) return 'attractions';

    return null;
  }

  String? _tripadvisorString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return null;
  }

  double? _tripadvisorDouble(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  double? _tripadvisorRating(Map<String, dynamic> payload) {
    return _tripadvisorDouble(payload, ['rating', 'bubble_rating', 'score']);
  }

  String? _tripadvisorPhotoUrl(Map<String, dynamic>? payload) {
    if (payload == null) {
      return null;
    }

    final direct = _recursivePhotoUrlSearch(payload);
    if (direct != null) {
      return direct;
    }

    return null;
  }

  String? _recursivePhotoUrlSearch(dynamic value) {
    if (value is Map) {
      final typed = value.cast<dynamic, dynamic>();
      for (final entry in typed.entries) {
        final key = entry.key.toString().toLowerCase();
        final child = entry.value;
        if (key.contains('url') &&
            child is String &&
            child.startsWith('http')) {
          return child;
        }
        final nested = _recursivePhotoUrlSearch(child);
        if (nested != null) {
          return nested;
        }
      }
    } else if (value is List) {
      for (final item in value) {
        final nested = _recursivePhotoUrlSearch(item);
        if (nested != null) {
          return nested;
        }
      }
    }

    return null;
  }

  String? _osmRating(Map<String, dynamic> tags) {
    final raw = tags['rating']?.toString();
    return raw == null || raw.trim().isEmpty ? null : raw.trim();
  }

  double? _osmScore(Map<String, dynamic> tags) {
    final raw = tags['rating'];
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      return double.tryParse(raw);
    }
    final stars = tags['stars'];
    if (stars is num) {
      return stars.toDouble();
    }
    if (stars is String) {
      return double.tryParse(stars);
    }
    return null;
  }

  String? _imageUrlFromTags(Map<String, dynamic> tags) {
    final direct = tags['image']?.toString();
    if (direct != null && direct.startsWith('http')) {
      return direct;
    }

    final commons = tags['wikimedia_commons']?.toString();
    if (commons != null && commons.trim().isNotEmpty) {
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/${Uri.encodeComponent(commons.trim())}';
    }

    return null;
  }
}
