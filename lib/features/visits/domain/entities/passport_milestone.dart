class PassportMilestone {
  const PassportMilestone({
    required this.key,
    required this.requiredCountries,
    required this.titleKey,
    required this.subtitleKey,
  });

  final String key;
  final int requiredCountries;
  final String titleKey;
  final String subtitleKey;

  bool isUnlockedBy(int countryCount) => countryCount >= requiredCountries;

  double progressFor(int countryCount) {
    if (requiredCountries <= 0) return 1;
    final value = countryCount / requiredCountries;
    return value.clamp(0.0, 1.0);
  }
}
