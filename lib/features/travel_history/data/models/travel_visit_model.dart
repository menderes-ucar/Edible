import '../../domain/entities/travel_visit.dart';

class TravelVisitModel extends TravelVisit {
  const TravelVisitModel({
    required super.id,
    required super.countryCode,
    required super.countryName,
    required super.cityName,
    required super.visitDay,
    required super.firstSeenAt,
    required super.lastSeenAt,
    required super.detectionCount,
    super.latitude,
    super.longitude,
  });

  factory TravelVisitModel.fromMap(Map<String, dynamic> map) {
    final visitDay = DateTime.tryParse(
          (map['visit_day'] ?? '').toString(),
        ) ??
        DateTime.now();

    return TravelVisitModel(
      id: (map['id'] ?? '').toString(),
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      visitDay: visitDay,
      firstSeenAt: DateTime.tryParse(
            (map['first_seen_at'] ?? '').toString(),
          ) ??
          visitDay,
      lastSeenAt: DateTime.tryParse(
            (map['last_seen_at'] ?? '').toString(),
          ) ??
          visitDay,
      detectionCount: int.tryParse(
            (map['detection_count'] ?? '1').toString(),
          ) ??
          1,
      latitude: _doubleOrNull(map['latitude']),
      longitude: _doubleOrNull(map['longitude']),
    );
  }

  static double? _doubleOrNull(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}
