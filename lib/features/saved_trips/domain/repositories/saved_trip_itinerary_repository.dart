import '../../../explore/domain/entities/explore_content.dart';
import '../entities/saved_trip_itinerary.dart';

abstract interface class SavedTripItineraryRepository {
  Future<List<Map<String, dynamic>>> getRawStops(String tripId);

  Future<void> replaceItinerary({
    required String tripId,
    required List<GeneratedItineraryStop> stops,
  });

  Future<SavedTripItineraryStop> addStop({
    required String tripId,
    required String contentId,
    required int dayIndex,
    required int startMinute,
    required int sortOrder,
    required ExploreContent content,
  });

  Future<void> updateStop({
    required String stopId,
    required int dayIndex,
    required int startMinute,
    required int sortOrder,
  });

  Future<void> updateStopsBatch({
    required String tripId,
    required List<SavedTripItineraryStop> stops,
  });

  Future<void> deleteStop(String stopId);
}
