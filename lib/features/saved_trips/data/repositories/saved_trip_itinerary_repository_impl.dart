import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/saved_trip_itinerary.dart';
import '../../domain/repositories/saved_trip_itinerary_repository.dart';
import '../datasources/saved_trip_itinerary_remote_data_source.dart';

class SavedTripItineraryRepositoryImpl
    implements SavedTripItineraryRepository {
  const SavedTripItineraryRepositoryImpl({
    required SavedTripItineraryRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SavedTripItineraryRemoteDataSource _remoteDataSource;

  @override
  Future<List<Map<String, dynamic>>> getRawStops(String tripId) {
    return _remoteDataSource.getRawStops(tripId);
  }

  @override
  Future<void> replaceItinerary({
    required String tripId,
    required List<GeneratedItineraryStop> stops,
  }) {
    return _remoteDataSource.replaceItinerary(
      tripId: tripId,
      stops: stops,
    );
  }

  @override
  Future<SavedTripItineraryStop> addStop({
    required String tripId,
    required String contentId,
    required int dayIndex,
    required int startMinute,
    required int sortOrder,
    required ExploreContent content,
  }) {
    return _remoteDataSource.addStop(
      tripId: tripId,
      contentId: contentId,
      dayIndex: dayIndex,
      startMinute: startMinute,
      sortOrder: sortOrder,
      content: content,
    );
  }

  @override
  Future<void> updateStop({
    required String stopId,
    required int dayIndex,
    required int startMinute,
    required int sortOrder,
  }) {
    return _remoteDataSource.updateStop(
      stopId: stopId,
      dayIndex: dayIndex,
      startMinute: startMinute,
      sortOrder: sortOrder,
    );
  }

  @override
  Future<void> updateStopsBatch({
    required String tripId,
    required List<SavedTripItineraryStop> stops,
  }) {
    return _remoteDataSource.updateStopsBatch(
      tripId: tripId,
      stops: stops,
    );
  }

  @override
  Future<void> deleteStop(String stopId) {
    return _remoteDataSource.deleteStop(stopId);
  }
}
