import '../../domain/entities/travel_memory.dart';

class TravelMemoryModel extends TravelMemory {
  const TravelMemoryModel({
    required super.id,
    required super.travelVisitId,
    required super.countryCode,
    required super.countryName,
    required super.cityName,
    required super.visitDate,
    required super.title,
    required super.note,
    required super.favoriteFood,
    required super.photoPaths,
    required super.createdAt,
    required super.updatedAt,
    super.rating,
    super.mood,
  });

  factory TravelMemoryModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return TravelMemoryModel(
      id: (map['id'] ?? '').toString(),
      travelVisitId: (map['travel_visit_id'] ?? '').toString(),
      countryCode: (map['country_code'] ?? '').toString(),
      countryName: (map['country_name'] ?? '').toString(),
      cityName: (map['city_name'] ?? '').toString(),
      visitDate: DateTime.tryParse(
            (map['visit_date'] ?? '').toString(),
          ) ??
          now,
      title: (map['title'] ?? '').toString(),
      note: (map['note'] ?? '').toString(),
      favoriteFood: (map['favorite_food'] ?? '').toString(),
      rating: int.tryParse((map['rating'] ?? '').toString()),
      mood: TravelMood.fromValue(map['mood']?.toString()),
      photoPaths: ((map['photo_paths'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
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
