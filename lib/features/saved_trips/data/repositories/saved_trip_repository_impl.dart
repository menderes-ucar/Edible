import '../../domain/entities/saved_trip.dart';
import '../../domain/entities/saved_trip_draft.dart';
import '../../domain/repositories/saved_trip_repository.dart';
import '../datasources/saved_trip_remote_data_source.dart';

class SavedTripRepositoryImpl implements SavedTripRepository {
  const SavedTripRepositoryImpl({
    required SavedTripRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SavedTripRemoteDataSource _remoteDataSource;

  @override
  Future<List<SavedTrip>> getTrips() {
    return _remoteDataSource.getTrips();
  }

  @override
  Future<SavedTrip?> getTrip(String tripId) {
    return _remoteDataSource.getTrip(tripId);
  }

  @override
  Future<SavedTrip> createTrip(SavedTripDraft draft) {
    return _remoteDataSource.createTrip(draft);
  }

  @override
  Future<SavedTrip> updateTrip({
    required String tripId,
    required SavedTripDraft draft,
  }) {
    return _remoteDataSource.updateTrip(
      tripId: tripId,
      draft: draft,
    );
  }

  @override
  Future<void> deleteTrip(String tripId) {
    return _remoteDataSource.deleteTrip(tripId);
  }

  @override
  Future<void> addContent({
    required String tripId,
    required String contentId,
  }) {
    return _remoteDataSource.addContent(
      tripId: tripId,
      contentId: contentId,
    );
  }

  @override
  Future<void> removeContent({
    required String tripId,
    required String contentId,
  }) {
    return _remoteDataSource.removeContent(
      tripId: tripId,
      contentId: contentId,
    );
  }
}
