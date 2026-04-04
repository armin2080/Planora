import 'google_maps_link_parser.dart';

class SharedLocationImportService {
  const SharedLocationImportService();

  bool canImportLocation(String? sharedText) {
    final normalized = sharedText?.trim();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }

    if (GoogleMapsLinkParser.parse(normalized) != null) {
      return true;
    }

    final urls = RegExp(r'https?://[^\s]+')
        .allMatches(normalized)
        .map((match) => match.group(0))
        .whereType<String>();

    for (final url in urls) {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        continue;
      }

      final host = uri.host.toLowerCase();
      if (host.contains('google.') ||
          host.contains('maps.app.goo.gl') ||
          host == 'goo.gl' ||
          host.endsWith('.goo.gl')) {
        return true;
      }
    }

    return false;
  }
}
