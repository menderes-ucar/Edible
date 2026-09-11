enum TourStopKind {
  place,
  food,
  drink,
  snack,
  culture,
  nature,
  shopping,
  entertainment,
  accommodation,
  transportation,
  other,
}

class TourStop {
  const TourStop({
    required this.id,
    required this.dayIndex,
    required this.orderIndex,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.imageAttribution,
    this.latitude,
    this.longitude,
  });

  final String id;
  final int dayIndex;
  final int orderIndex;
  final TourStopKind kind;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String imageAttribution;
  final double? latitude;
  final double? longitude;
}

class TourPackage {
  const TourPackage({
    required this.id,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.title,
    required this.summary,
    required this.days,
    required this.coverImageUrl,
    required this.coverAttribution,
    required this.favoriteCount,
    required this.ratingAverage,
    required this.ratingCount,
    required this.stops,
  });

  final String id;
  final String countryCode;
  final String countryName;
  final String cityName;
  final String title;
  final String summary;
  final int days;
  final String coverImageUrl;
  final String coverAttribution;
  final int favoriteCount;
  final double ratingAverage;
  final int ratingCount;
  final List<TourStop> stops;

  TourPackage copyWithRatings({
    double? ratingAverage,
    int? ratingCount,
    int? favoriteCount,
  }) => TourPackage(
        id: id,
        countryCode: countryCode,
        countryName: countryName,
        cityName: cityName,
        title: title,
        summary: summary,
        days: days,
        coverImageUrl: coverImageUrl,
        coverAttribution: coverAttribution,
        favoriteCount: favoriteCount ?? this.favoriteCount,
        ratingAverage: ratingAverage ?? this.ratingAverage,
        ratingCount: ratingCount ?? this.ratingCount,
        stops: stops,
      );
}
