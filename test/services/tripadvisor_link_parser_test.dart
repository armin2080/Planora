import 'package:flutter_test/flutter_test.dart';
import 'package:planora/services/tripadvisor_link_parser.dart';

void main() {
  group('TripadvisorLinkParser.parse', () {
    test('returns null for non-Tripadvisor links', () {
      const link = 'https://www.google.com/maps?q=48.858370,2.294481';
      expect(TripadvisorLinkParser.parse(link), isNull);
    });

    test('extracts attraction name and city hint from review URL', () {
      const link =
          'https://www.tripadvisor.com/Attraction_Review-g187147-d188151-Reviews-Eiffel_Tower-Paris_Ile_de_France.html';

      final parsed = TripadvisorLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.sourceUrl, link);
      expect(parsed.name, 'Eiffel Tower');
      expect(parsed.cityHint, 'Paris Ile de France');
      expect(parsed.category, isNull);
    });

    test('maps known category code from activities URL', () {
      const link =
          'https://www.tripadvisor.com/Attractions-g187147-Activities-c49-Paris_Ile_de_France.html';

      final parsed = TripadvisorLinkParser.parse(link);

      expect(parsed, isNotNull);
      expect(parsed!.category, 'Museums');
      expect(parsed.name, 'Paris Ile de France');
    });
  });
}
