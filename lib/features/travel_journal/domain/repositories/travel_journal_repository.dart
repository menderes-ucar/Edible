import '../entities/travel_memory.dart';
import '../entities/travel_memory_draft.dart';

abstract interface class TravelJournalRepository {
  Future<TravelMemory?> getForVisit(String travelVisitId);

  Future<TravelMemory> save(TravelMemoryDraft draft);

  Future<String> uploadPhoto({
    required String travelVisitId,
    required String filePath,
  });

  Future<void> deletePhoto(String storagePath);

  Future<String> createSignedPhotoUrl(
    String storagePath, {
    int expiresInSeconds = 3600,
  });
}
