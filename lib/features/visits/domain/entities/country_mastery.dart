class CountryMastery {
  const CountryMastery({
    required this.countryCode,
    required this.countryName,
    required this.completedCount,
    required this.totalCount,
    required this.placeCompleted,
    required this.placeTotal,
    required this.tasteCompleted,
    required this.tasteTotal,
    required this.cultureCompleted,
    required this.cultureTotal,
  });

  final String countryCode;
  final String countryName;

  final int completedCount;
  final int totalCount;

  final int placeCompleted;
  final int placeTotal;

  final int tasteCompleted;
  final int tasteTotal;

  final int cultureCompleted;
  final int cultureTotal;

  double get completion =>
      totalCount <= 0 ? 0 : (completedCount / totalCount).clamp(0.0, 1.0);

  int get percent => (completion * 100).round();

  bool get isComplete => totalCount > 0 && completedCount >= totalCount;

  String get rankKey {
    if (isComplete) return 'countryMasteryLegend';
    if (completion >= 0.75) return 'countryMasteryInsider';
    if (completion >= 0.40) return 'countryMasteryExplorer';
    return 'countryMasteryNewcomer';
  }
}
