import '../entities/arrival_welcome_history.dart';
import '../entities/detected_arrival.dart';

class ShouldShowArrivalWelcome {
  const ShouldShowArrivalWelcome({
    this.repeatAfter = const Duration(days: 7),
  });

  final Duration repeatAfter;

  bool call({
    required DetectedArrival arrival,
    required ArrivalWelcomeHistory? history,
    required DateTime now,
  }) {
    if (history == null) return true;

    if (!history.matches(
      countryCode: arrival.countryCode,
      cityName: arrival.cityName,
    )) {
      return true;
    }

    return now.difference(history.shownAt) >= repeatAfter;
  }
}
