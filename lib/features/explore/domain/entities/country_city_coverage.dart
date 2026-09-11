
class CountryCityCoverage {
  const CountryCityCoverage({
    required this.countryCode,
    required this.cityCount,
    required this.readyCityCount,
    required this.incompleteCityCount,
    required this.readyPercent,
  });

  final String countryCode;
  final int cityCount;
  final int readyCityCount;
  final int incompleteCityCount;
  final double readyPercent;

  bool get isFullyReady => cityCount > 0 && incompleteCityCount == 0;
}
