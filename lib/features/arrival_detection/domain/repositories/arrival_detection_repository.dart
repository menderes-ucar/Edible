import '../entities/arrival_welcome_history.dart';

abstract interface class ArrivalDetectionRepository {
  Future<ArrivalWelcomeHistory?> getLastWelcome();

  Future<void> saveWelcome({
    required String countryCode,
    required String cityName,
    required DateTime shownAt,
  });
}
