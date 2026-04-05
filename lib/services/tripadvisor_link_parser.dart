class ParsedTripadvisorLink {
  ParsedTripadvisorLink({
    required this.sourceUrl,
    this.name,
    this.category,
    this.cityHint,
  });

  final String sourceUrl;
  final String? name;
  final String? category;
  final String? cityHint;
}

class TripadvisorLinkParser {
  static ParsedTripadvisorLink? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('tripadvisor.')) {
      return null;
    }

    final path = Uri.decodeComponent(uri.path);
    final categoryCode = RegExp(r'-c(\d+)-').firstMatch(path)?.group(1);

    final extractedName = _extractName(path);
    final cityHint = _extractCityHint(path);

    return ParsedTripadvisorLink(
      sourceUrl: trimmed,
      name: extractedName,
      category: _categoryFromCode(categoryCode),
      cityHint: cityHint,
    );
  }

  static String? _extractName(String path) {
    final reviewMatch = RegExp(r'-Reviews-([^-.]+)').firstMatch(path);
    if (reviewMatch != null) {
      return _normalizeSegment(reviewMatch.group(1));
    }

    final activityMatch =
        RegExp(r'Activities?-(?:c\d+-)?([^-.]+)').firstMatch(path);
    if (activityMatch != null) {
      return _normalizeSegment(activityMatch.group(1));
    }

    return null;
  }

  static String? _extractCityHint(String path) {
    final reviewMatch = RegExp(r'-Reviews-[^-.]+-([^-.]+)').firstMatch(path);
    if (reviewMatch != null) {
      return _normalizeSegment(reviewMatch.group(1));
    }

    return null;
  }

  static String? _normalizeSegment(String? raw) {
    if (raw == null) {
      return null;
    }

    final normalized = raw.replaceAll('_', ' ').trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String? _categoryFromCode(String? code) {
    switch (code) {
      case '49':
        return 'Museums';
      case '47':
        return 'Sights & Landmarks';
      case '57':
        return 'Nature & Parks';
      case '61':
        return 'Outdoor Activities';
      case '56':
        return 'Classes & Workshops';
      case '55':
        return 'Tours';
      case '20':
        return 'Shopping';
      case '24':
        return 'Food & Drink';
      case '36':
        return 'Nightlife';
      default:
        return null;
    }
  }
}
