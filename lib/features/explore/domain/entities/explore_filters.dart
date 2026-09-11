enum ExploreSort {
  recommended,
  featuredFirst,
  alphabetical,
}

class ExploreFilters {
  const ExploreFilters({
    this.countryCode,
    this.cityName,
    this.featuredOnly = false,
    this.maxDistanceKm,
    this.sort = ExploreSort.recommended,
  });

  final String? countryCode;
  final String? cityName;
  final bool featuredOnly;
  final double? maxDistanceKm;
  final ExploreSort sort;

  bool get isEmpty =>
      (countryCode == null || countryCode!.trim().isEmpty) &&
      (cityName == null || cityName!.trim().isEmpty) &&
      !featuredOnly &&
      maxDistanceKm == null &&
      sort == ExploreSort.recommended;

  int get activeCount {
    var count = 0;
    if (countryCode != null && countryCode!.trim().isNotEmpty) count++;
    if (cityName != null && cityName!.trim().isNotEmpty) count++;
    if (featuredOnly) count++;
    if (maxDistanceKm != null) count++;
    if (sort != ExploreSort.recommended) count++;
    return count;
  }

  ExploreFilters copyWith({
    String? countryCode,
    bool clearCountry = false,
    String? cityName,
    bool clearCity = false,
    bool? featuredOnly,
    double? maxDistanceKm,
    bool clearDistance = false,
    ExploreSort? sort,
  }) {
    return ExploreFilters(
      countryCode: clearCountry ? null : countryCode ?? this.countryCode,
      cityName: clearCity ? null : cityName ?? this.cityName,
      featuredOnly: featuredOnly ?? this.featuredOnly,
      maxDistanceKm:
          clearDistance ? null : maxDistanceKm ?? this.maxDistanceKm,
      sort: sort ?? this.sort,
    );
  }
}
