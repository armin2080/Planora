import 'dart:convert';

import 'package:http/http.dart' as http;

class PlacePhotoLookupService {
  static const _timeout = Duration(seconds: 10);
  static const _userAgent = 'Planora/1.0 (photo-lookup)';

  final Map<String, String?> _cache = <String, String?>{};

  Future<String?> findPhotoUrl({
    required String placeName,
    String? contextHint,
  }) async {
    final normalizedName = placeName.trim();
    if (normalizedName.isEmpty) {
      return null;
    }

    final cacheKey = '${normalizedName.toLowerCase()}|${(contextHint ?? '').toLowerCase()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final queries = <String>[
      if (contextHint != null && contextHint.trim().isNotEmpty)
        '$normalizedName ${contextHint.trim()}',
      normalizedName,
    ];

    for (final query in queries) {
      final url = await _searchWikipediaThumbnail(query);
      if (url != null) {
        _cache[cacheKey] = url;
        return url;
      }
    }

    _cache[cacheKey] = null;
    return null;
  }

  Future<String?> _searchWikipediaThumbnail(String query) async {
    final uri = Uri.https('en.wikipedia.org', '/w/api.php', {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': query,
      'gsrlimit': '1',
      'prop': 'pageimages',
      'piprop': 'thumbnail',
      'pithumbsize': '700',
      'format': 'json',
      'utf8': '1',
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
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final queryData = decoded['query'];
      if (queryData is! Map<String, dynamic>) {
        return null;
      }

      final pages = queryData['pages'];
      if (pages is! Map<String, dynamic> || pages.isEmpty) {
        return null;
      }

      for (final page in pages.values) {
        if (page is! Map<String, dynamic>) {
          continue;
        }

        final thumbnail = page['thumbnail'];
        if (thumbnail is! Map<String, dynamic>) {
          continue;
        }

        final source = thumbnail['source']?.toString().trim();
        if (source != null && source.isNotEmpty) {
          return source;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
