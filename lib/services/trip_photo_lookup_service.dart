import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TripPhotoLookupService {
  static const _timeout = Duration(seconds: 10);
  static const _userAgent = 'Planora/1.0 (trip-photo-lookup)';

  final Map<String, String?> _cache = <String, String?>{};

  /// Finds and downloads a photo for a trip.
  /// Returns the local file path if successful, null otherwise.
  Future<String?> findAndDownloadPhotoUrl({
    required String tripName,
  }) async {
    final normalizedName = tripName.trim();
    if (normalizedName.isEmpty) {
      return null;
    }

    final cacheKey = normalizedName.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final imageUrl = await _searchWikipediaThumbnail(normalizedName);
    if (imageUrl == null) {
      _cache[cacheKey] = null;
      return null;
    }

    final filePath = await _downloadAndSaveImage(imageUrl, normalizedName);
    _cache[cacheKey] = filePath;
    return filePath;
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

  Future<String?> _downloadAndSaveImage(String imageUrl, String tripName) async {
    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'User-Agent': _userAgent,
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final appDocDir = await getApplicationDocumentsDirectory();
      final tripsPhotoDir = Directory('${appDocDir.path}/trip_photos');
      if (!await tripsPhotoDir.exists()) {
        await tripsPhotoDir.create(recursive: true);
      }

      // Sanitize trip name for filename
      final sanitizedName = tripName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = '${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoFile = File('${tripsPhotoDir.path}/$fileName');

      await photoFile.writeAsBytes(response.bodyBytes);
      return photoFile.path;
    } catch (_) {
      return null;
    }
  }
}
