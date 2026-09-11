
import 'package:flutter_test/flutter_test.dart';
import 'package:edible/features/explore/domain/entities/country_city_coverage.dart';

void main() {
  test('country is fully ready only when every city has content coverage', () {
    expect(
      const CountryCityCoverage(
        countryCode:'US', cityCount:100, readyCityCount:100,
        incompleteCityCount:0, readyPercent:100,
      ).isFullyReady,
      isTrue,
    );
    expect(
      const CountryCityCoverage(
        countryCode:'CN', cityCount:100, readyCityCount:99,
        incompleteCityCount:1, readyPercent:99,
      ).isFullyReady,
      isFalse,
    );
  });
}
