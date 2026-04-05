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

  test('returns true for a Tripadvisor attraction link', () {
    const link =
        'https://www.tripadvisor.com/Attraction_Review-g187147-d188151-Reviews-Eiffel_Tower-Paris_Ile_de_France.html';
    expect(service.canImportLocation(link), isTrue);
  });

  test('returns true when Tripadvisor link appears inside shared text', () {
    const sharedText =
        'Check this out: https://www.tripadvisor.com/Attraction_Review-g60763-d105127-Reviews-The_Metropolitan_Museum_of_Art-New_York_City_New_York.html';
    expect(service.canImportLocation(sharedText), isTrue);
  });
}
