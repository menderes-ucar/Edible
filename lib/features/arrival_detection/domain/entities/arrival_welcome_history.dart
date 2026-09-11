class ArrivalWelcomeHistory {
  const ArrivalWelcomeHistory({
    required this.countryCode,
    required this.cityName,
    required this.shownAt,
  });

  final String countryCode;
  final String cityName;
  final DateTime shownAt;

  bool matches({
    required String countryCode,
    required String cityName,
  }) {
    return this.countryCode.toLowerCase() == countryCode.toLowerCase() &&
        this.cityName.toLowerCase() == cityName.toLowerCase();
  }
}
