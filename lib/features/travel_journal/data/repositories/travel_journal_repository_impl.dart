import '../../domain/entities/travel_memory.dart';
import '../../domain/entities/travel_memory_draft.dart';
import '../../domain/repositories/travel_journal_repository.dart';
import '../datasources/travel_journal_remote_data_source.dart';

class TravelJournalRepositoryImpl implements TravelJournalRepository {
  const TravelJournalRepositoryImpl({
    required TravelJournalRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final TravelJournalRemoteDataSource _remoteDataSource;

  @override
  Future<TravelMemory?> getForVisit(String travelVisitId) {
    return _remoteDataSource.getForVisit(travelVisitId);
  }

  @override
  Future<TravelMemory> save(TravelMemoryDraft draft) {
    return _remoteDataSource.save(draft);
  }

  @override
  Future<String> uploadPhoto({
    required String travelVisitId,
    required String filePath,
  }) {
    return _remoteDataSource.uploadPhoto(
      travelVisitId: travelVisitId,
      filePath: filePath,
    );
  }

  @override
  Future<void> deletePhoto(String storagePath) {
    return _remoteDataSource.deletePhoto(storagePath);
  }

  @override
  Future<String> createSignedPhotoUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  }) {
    return _remoteDataSource.createSignedPhotoUrl(
      storagePath,
      expiresInSeconds: expiresInSeconds,
    );
  }
}
