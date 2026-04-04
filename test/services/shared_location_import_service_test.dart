import 'package:flutter_test/flutter_test.dart';
import 'package:planora/services/shared_location_import_service.dart';

void main() {
  const service = SharedLocationImportService();

  test('returns false for null or empty input', () {
    expect(service.canImportLocation(null), isFalse);
    expect(service.canImportLocation(''), isFalse);
    expect(service.canImportLocation('   '), isFalse);
  });

  test('returns true for a valid Google Maps link', () {
    const link = 'https://www.google.com/maps?q=48.858370,2.294481';
    expect(service.canImportLocation(link), isTrue);
  });

  test('returns false for text without map coordinates/link', () {
    const text = 'Meet me near the station tomorrow morning.';
    expect(service.canImportLocation(text), isFalse);
  });

  test('returns true for Google Maps short link', () {
    const shortLink = 'https://maps.app.goo.gl/AbCdEf12345';
    expect(service.canImportLocation(shortLink), isTrue);
  });
}
