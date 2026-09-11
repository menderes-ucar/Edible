class TravelYearSummary {
  const TravelYearSummary({
    required this.year,
    required this.countryCount,
    required this.cityCount,
    required this.travelDayCount,
    required this.photoCount,
    required this.activeYears,
  });

  final int year;
  final int countryCount;
  final int cityCount;
  final int travelDayCount;
  final int photoCount;
  final List<int> activeYears;

  int get travelStreakYears {
    if (activeYears.isEmpty) return 0;

    final years = activeYears.toSet().toList()..sort();
    var streak = 1;

    for (var i = years.length - 1; i > 0; i--) {
      if (years[i] - years[i - 1] == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int? get latestActiveYear =>
      activeYears.isEmpty ? null : (activeYears.toList()..sort()).last;

  bool get hasTravel => travelDayCount > 0;
}
