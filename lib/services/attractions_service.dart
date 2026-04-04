import 'dart:convert';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/attraction_suggestion.dart';

class AttractionsService {
  static const _timeout = Duration(seconds: 15);
  static const _userAgent = 'Planora/1.0 (contact: planora-app)';
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
    final query =
        '''[out:json][timeout:15];(node["tourism"="attraction"](around:20000,$lat,$lng);node["tourism"="museum"](around:20000,$lat,$lng);node["amenity"="restaurant"](around:20000,$lat,$lng);node["leisure"="park"](around:20000,$lat,$lng););out geom;''';
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
      for (final el in elements.take(15)) {
        final tags = (el['tags'] ?? {}) as Map<String, dynamic>;
        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue;
        final latValue = el['lat'];
        final lonValue = el['lon'];
        attractions.add(AttractionSuggestion(
          tripId: tripId,
          name: name,
          lat: latValue is num ? latValue.toDouble() : null,
          lng: lonValue is num ? lonValue.toDouble() : null,
          type: _getType(tags),
          description: tags['description'] as String?,
          rating: tags['rating'] as String?,
          url: (tags['website'] ?? tags['url'])?.toString(),
        ));
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
        tags['historic'] ??
        'place') as String;
  }
}
