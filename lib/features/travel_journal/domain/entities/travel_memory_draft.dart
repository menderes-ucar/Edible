import 'travel_memory.dart';

class TravelMemoryDraft {
  const TravelMemoryDraft({
    required this.travelVisitId,
    required this.countryCode,
    required this.countryName,
    required this.cityName,
    required this.visitDate,
    required this.title,
    required this.note,
    required this.favoriteFood,
    required this.photoPaths,
    this.rating,
    this.mood,
  });

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
  final List<String> photoPaths;
}
