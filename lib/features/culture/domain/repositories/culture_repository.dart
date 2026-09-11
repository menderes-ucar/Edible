import '../entities/culture_guide.dart';

abstract interface class CultureRepository {
  Future<CultureGuide> getGuide({
    required String countryCode,
    required String cityName,
    required String languageCode,
  });
}
