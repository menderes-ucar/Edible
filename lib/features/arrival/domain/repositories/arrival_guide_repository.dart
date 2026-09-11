import '../entities/arrival_guide.dart';

abstract interface class ArrivalGuideRepository {
  Future<ArrivalGuide> getGuide({
    required String countryCode,
    required String cityName,
    required String languageCode,
  });
}
