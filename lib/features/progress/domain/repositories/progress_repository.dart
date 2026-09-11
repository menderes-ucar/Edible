import '../entities/content_progress.dart';
import '../entities/trip_collection.dart';

abstract interface class ProgressRepository {
  Future<Set<String>> getVisitedIds();
  Future<Set<String>> getTriedIds();

  Future<void> setProgress({
    required String contentId,
    required ContentProgressType type,
    required bool enabled,
  });

  Future<List<TripCollection>> getCollections();

  Future<TripCollection> createCollection({
    required String name,
    String? description,
  });

  Future<TripCollection> updateCollection({
    required String collectionId,
    required String name,
    String? description,
  });

  Future<void> deleteCollection(String collectionId);

  Future<void> addContentToCollection({
    required String collectionId,
    required String contentId,
  });

  Future<void> removeContentFromCollection({
    required String collectionId,
    required String contentId,
  });
}
