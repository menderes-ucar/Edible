import '../../domain/entities/saved_trip.dart';

class SavedTripModel extends SavedTrip {
  const SavedTripModel({
    required super.id,
    required super.name,
    required super.countryCode,
    required super.countryName,
    required super.cityName,
    required super.startDate,
    required super.endDate,
    required super.notes,
    required super.contentIds,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SavedTripModel.fromMap(
    Map<String, dynamic> map, {
    List<String> contentIds = const [],
  }) {
    final now = DateTime.now();

    return SavedTripModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      startDate: DateTime.tryParse(
            (map['start_date'] ?? '').toString(),
          ) ??
          now,
      endDate: DateTime.tryParse(
            (map['end_date'] ?? '').toString(),
          ) ??
          now,
      notes: (map['notes'] ?? '').toString(),
      contentIds: List.unmodifiable(contentIds),
      createdAt: DateTime.tryParse(
            (map['created_at'] ?? '').toString(),
          ) ??
          now,
      updatedAt: DateTime.tryParse(
            (map['updated_at'] ?? '').toString(),
          ) ??
          now,
    );
  }
}
