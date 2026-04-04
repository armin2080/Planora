class ParsedGoogleMapsLink {
  ParsedGoogleMapsLink({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  final double latitude;
  final double longitude;
  final String? name;
}

class GoogleMapsLinkParser {
  static ParsedGoogleMapsLink? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final direct = _parseFromUrl(trimmed);
    if (direct != null) {
      return direct;
    }

    final embeddedUrlMatch = RegExp(r'https?://[^\s]+').firstMatch(trimmed);
    if (embeddedUrlMatch != null) {
      final embedded = _parseFromUrl(embeddedUrlMatch.group(0)!);
      if (embedded != null) {
        return embedded;
      }
    }

    return null;
  }

  static ParsedGoogleMapsLink? _parseFromUrl(String rawUrl) {
    final sanitized = rawUrl.trim();

    Uri? uri;
    try {
      uri = Uri.parse(sanitized);
    } catch (_) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!(host.contains('google.') ||
        host.contains('goo.gl') ||
        host.contains('maps.app.goo.gl'))) {
      return null;
    }

    final fromAtPath = _extractAtCoordinates(uri.path);
    if (fromAtPath != null) {
      return ParsedGoogleMapsLink(
        latitude: fromAtPath.$1,
        longitude: fromAtPath.$2,
        name: _extractName(uri),
      );
    }

    final fromQ = _extractCoordinatesFromText(uri.queryParameters['q']);
    if (fromQ != null) {
      return ParsedGoogleMapsLink(
        latitude: fromQ.$1,
        longitude: fromQ.$2,
        name: _extractName(uri),
      );
    }

    final fromQuery = _extractCoordinatesFromText(uri.queryParameters['query']);
    if (fromQuery != null) {
      return ParsedGoogleMapsLink(
        latitude: fromQuery.$1,
        longitude: fromQuery.$2,
        name: _extractName(uri),
      );
    }

    final fromLl = _extractCoordinatesFromText(uri.queryParameters['ll']);
    if (fromLl != null) {
      return ParsedGoogleMapsLink(
        latitude: fromLl.$1,
        longitude: fromLl.$2,
        name: _extractName(uri),
      );
    }

    final fromData = _extractBangCoordinates(
        uri.path + (uri.hasQuery ? '?${uri.query}' : ''));
    if (fromData != null) {
      return ParsedGoogleMapsLink(
        latitude: fromData.$1,
        longitude: fromData.$2,
        name: _extractName(uri),
      );
    }

    return null;
  }

  static (double, double)? _extractAtCoordinates(String path) {
    final match =
        RegExp(r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)').firstMatch(path);
    if (match == null) {
      return null;
    }

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) {
      return null;
    }

    return (lat, lng);
  }

  static (double, double)? _extractBangCoordinates(String text) {
    final latMatch = RegExp(r'!3d(-?\d+(?:\.\d+)?)').firstMatch(text);
    final lngMatch = RegExp(r'!4d(-?\d+(?:\.\d+)?)').firstMatch(text);
    if (latMatch == null || lngMatch == null) {
      return null;
    }

    final lat = double.tryParse(latMatch.group(1)!);
    final lng = double.tryParse(lngMatch.group(1)!);
    if (lat == null || lng == null) {
      return null;
    }

    return (lat, lng);
  }

  static (double, double)? _extractCoordinatesFromText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final decoded = Uri.decodeComponent(text);
    final coordMatch = RegExp(r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)')
        .firstMatch(decoded);
    if (coordMatch == null) {
      return null;
    }

    final lat = double.tryParse(coordMatch.group(1)!);
    final lng = double.tryParse(coordMatch.group(2)!);
    if (lat == null || lng == null) {
      return null;
    }

    return (lat, lng);
  }

  static String? _extractName(Uri uri) {
    final segments = uri.pathSegments;
    final placeIndex = segments.indexOf('place');
    if (placeIndex != -1 && placeIndex + 1 < segments.length) {
      final raw = Uri.decodeComponent(segments[placeIndex + 1])
          .replaceAll('+', ' ')
          .trim();
      if (raw.isNotEmpty) {
        return raw;
      }
    }

    final q = uri.queryParameters['q'];
    if (q != null) {
      final decoded = Uri.decodeComponent(q);
      final withoutCoords = decoded
          .replaceFirst(
              RegExp(r'^\s*-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?\s*$'), '')
          .trim();
      if (withoutCoords.isNotEmpty) {
        return withoutCoords;
      }
    }

    return null;
  }
}
