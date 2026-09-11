import '../entities/saved_trip.dart';
import '../entities/saved_trip_draft.dart';

abstract interface class SavedTripRepository {
  Future<List<SavedTrip>> getTrips();

  Future<SavedTrip?> getTrip(String tripId);

  Future<SavedTrip> createTrip(SavedTripDraft draft);

  Future<SavedTrip> updateTrip({
    required String tripId,
    required SavedTripDraft draft,
  });

  Future<void> deleteTrip(String tripId);

  Future<void> addContent({
    required String tripId,
    required String contentId,
  });

  Future<void> removeContent({
    required String tripId,
    required String contentId,
  });
}
