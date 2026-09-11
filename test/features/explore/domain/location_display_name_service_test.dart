
import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/services/location_display_name_service.dart';

void main() {
  const service = LocationDisplayNameService();

  test('Turkish user gets Turkish country translation instead of native-only script', () {
    expect(
      service.countryName(
        locale: 'tr-TR',
        countryCode: 'CN',
        fallbackName: '中国',
        nativeName: '中国',
        translations: const {'tr': 'Çin', 'en': 'China'},
      ),
      'Çin',
    );
  });

  test('falls back to English/Latin city name when native script is unreadable for locale', () {
    expect(
      service.cityName(
        locale: 'tr',
        fallbackName: '北京',
        asciiName: 'Beijing',
        nativeName: '北京',
      ),
      'Beijing',
    );
  });

  test('Arabic locale may use Arabic preferred translation', () {
    expect(
      service.countryName(
        locale: 'ar',
        countryCode: 'KZ',
        fallbackName: 'Kazakhstan',
        translations: const {'ar': 'كازاخستان', 'tr': 'Kazakistan'},
      ),
      'كازاخستان',
    );
  });
}
