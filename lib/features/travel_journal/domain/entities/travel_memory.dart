enum TravelMood {
  happy,
  amazed,
  relaxed,
  adventurous;

  static TravelMood? fromValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    for (final mood in TravelMood.values) {
      if (mood.name == value.trim().toLowerCase()) {
        return mood;
      }
    }

    return null;
  }
}

class TravelMemory {
  const TravelMemory({
    required this.id,
    required this.travelVisitId,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.visitDate,
    required this.title,
    required this.note,
    required this.favoriteFood,
    required this.photoPaths,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.mood,
  });

  final String id;
  final String travelVisitId;
  final String countryCode;
  final String countryName;
  final String cityName;
  final DateTime visitDate;

  final String title;
  final String note;
  final String favoriteFood;
  final int? rating;
  final TravelMood? mood;

  /// Private Supabase Storage object paths.
  /// Never store expiring signed URLs in the database.
  final List<String> photoPaths;

  final DateTime createdAt;
  final DateTime updatedAt;
}
