class CountryQuest {
  const CountryQuest({
    required this.countryCode,
    required this.countryName,
    required this.completedCount,
    required this.totalCount,
    required this.nextContentId,
    required this.nextTitle,
    required this.nextCategory,
    required this.nextCityName,
  });

  final String countryCode;
  final String countryName;
  final int completedCount;
  final int totalCount;
  final String? nextContentId;
  final String? nextTitle;
  final String? nextCategory;
  final String? nextCityName;

  double get progress =>
      totalCount <= 0 ? 0 : (completedCount / totalCount).clamp(0.0, 1.0);

  int get percent => (progress * 100).round();

  bool get isComplete => totalCount > 0 && completedCount >= totalCount;

  bool get hasNext =>
      (nextContentId ?? '').trim().isNotEmpty &&
      (nextTitle ?? '').trim().isNotEmpty;
}
