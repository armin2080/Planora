import 'dart:convert';

import 'package:http/http.dart' as http;

import 'google_maps_link_parser.dart';
import 'place_photo_lookup_service.dart';
import 'tripadvisor_link_parser.dart';

class ParsedExternalLocation {
  ParsedExternalLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.googleMapsUrl,
    this.note,
    this.sourceUrl,
    this.source,
    this.category,
    this.resolutionHint,
    this.photoUrl,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String googleMapsUrl;
  final String? note;
  final String? sourceUrl;
  final String? source;
  final String? category;
  final String? resolutionHint;
  final String? photoUrl;
}

class _GeocodeResult {
  _GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.queryUsed,
  });

  final double latitude;
  final double longitude;
  final String queryUsed;
}

class ExternalLocationLinkImportService {
  ExternalLocationLinkImportService({PlacePhotoLookupService? photoLookup})
      : _photoLookup = photoLookup ?? PlacePhotoLookupService();

  static const _timeout = Duration(seconds: 12);
  static const _userAgent = 'Planora/1.0 (link-import)';
  final PlacePhotoLookupService _photoLookup;

  Future<ParsedExternalLocation?> parseAndResolve(
    String rawInput, {
    String? contextHint,
  }) async {
    final text = rawInput.trim();
    if (text.isEmpty) {
      return null;
    }

    final googleParsed = GoogleMapsLinkParser.parse(text);
    if (googleParsed != null) {
      final name = (googleParsed.name?.trim().isNotEmpty ?? false)
          ? googleParsed.name!.trim()
          : 'Imported location';
      final googleMapsUrl = _buildGoogleMapsUrl(
        googleParsed.latitude,
        googleParsed.longitude,
      );

      return ParsedExternalLocation(
        name: name,
        latitude: googleParsed.latitude,
        longitude: googleParsed.longitude,
        googleMapsUrl: googleMapsUrl,
        source: 'Google Maps',
      );
    }

    final tripadvisorParsed = TripadvisorLinkParser.parse(text);
    if (tripadvisorParsed == null) {
      return null;
    }

    final placeName = tripadvisorParsed.name?.trim();
    if (placeName == null || placeName.isEmpty) {
      return null;
    }

    final geocodeResult = await _geocodeWithHints(
      name: placeName,
      cityHint: tripadvisorParsed.cityHint,
      contextHint: contextHint,
    );
    if (geocodeResult == null) {
      return null;
    }

    final googleMapsUrl = _buildGoogleMapsUrl(
      geocodeResult.latitude,
      geocodeResult.longitude,
    );
    final resolutionHint = _buildResolutionHint(
      geocodeResult.queryUsed,
      placeName,
    );
    final note = _buildTripadvisorNote(
      sourceUrl: tripadvisorParsed.sourceUrl,
      category: tripadvisorParsed.category,
      cityHint: tripadvisorParsed.cityHint,
      googleMapsUrl: googleMapsUrl,
      resolutionHint: resolutionHint,
    );
    final photoUrl = await _photoLookup.findPhotoUrl(
      placeName: placeName,
      contextHint: tripadvisorParsed.cityHint ?? contextHint,
    );

    return ParsedExternalLocation(
      name: placeName,
      latitude: geocodeResult.latitude,
      longitude: geocodeResult.longitude,
      googleMapsUrl: googleMapsUrl,
      note: note,
      sourceUrl: tripadvisorParsed.sourceUrl,
      source: 'Tripadvisor',
      category: tripadvisorParsed.category,
      resolutionHint: resolutionHint,
      photoUrl: photoUrl,
    );
  }

  Future<_GeocodeResult?> _geocodeWithHints({
    required String name,
    String? cityHint,
    String? contextHint,
  }) async {
    final queries = <String>[
      if (cityHint != null && cityHint.trim().isNotEmpty)
        '$name, ${cityHint.trim()}',
      if (contextHint != null && contextHint.trim().isNotEmpty)
        '$name, ${contextHint.trim()}',
      name,
    ];

    for (final query in queries) {
      final result = await _geocode(query);
      if (result != null) {
        return _GeocodeResult(
          latitude: result.$1,
          longitude: result.$2,
          queryUsed: query,
        );
      }
    }

    return null;
  }

  Future<(double, double)?> _geocode(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '1',
      'addressdetails': '0',
    });

    try {
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
      if (decoded is! List || decoded.isEmpty) {
        return null;
      }

      final first = decoded.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) {
        return null;
      }

      return (lat, lon);
    } catch (_) {
      return null;
    }
  }

  String _buildGoogleMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  String _buildTripadvisorNote({
    required String sourceUrl,
    required String googleMapsUrl,
    String? category,
    String? cityHint,
    String? resolutionHint,
  }) {
    final lines = <String>[
      'Imported from Tripadvisor',
      if (category != null && category.trim().isNotEmpty)
        'Category: ${category.trim()}',
      if (cityHint != null && cityHint.trim().isNotEmpty)
        'City hint: ${cityHint.trim()}',
      if (resolutionHint != null && resolutionHint.trim().isNotEmpty)
        'Location match: ${resolutionHint.trim()}',
      'Source: $sourceUrl',
      'Google Maps: $googleMapsUrl',
    ];

    return lines.join('\n');
  }

  String? _buildResolutionHint(String queryUsed, String placeName) {
    if (queryUsed.trim() == placeName.trim()) {
      return 'Approximate (name-only geocoding)';
    }

    return 'Matched with destination hint';
  }
}
