import '../../domain/entities/content_progress.dart';
import '../../domain/entities/trip_collection.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl({
    required ProgressRemoteDataSource remoteDataSource,
  }) : _remote = remoteDataSource;

  final ProgressRemoteDataSource _remote;

  @override
  Future<Set<String>> getVisitedIds() {
    return _remote.getIds(ContentProgressType.visited);
  }

  @override
  Future<Set<String>> getTriedIds() {
    return _remote.getIds(ContentProgressType.tried);
  }

  @override
  Future<void> setProgress({
    required String contentId,
    required ContentProgressType type,
    required bool enabled,
  }) {
    return _remote.setProgress(
      contentId: contentId,
      type: type,
      enabled: enabled,
    );
  }

  @override
  Future<List<TripCollection>> getCollections() async {
    final rows = await _remote.getCollections();
    return rows.map(_collectionFromRow).toList(growable: false);
  }

  @override
  Future<TripCollection> createCollection({
    required String name,
    String? description,
  }) async {
    final row = await _remote.createCollection(
      name: name,
      description: description,
    );
    return _collectionFromRow(row);
  }

  @override
  Future<TripCollection> updateCollection({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    final row = await _remote.updateCollection(
      collectionId: collectionId,
      name: name,
      description: description,
    );
    final existing = await getCollections();
    final current = existing.where((item) => item.id == collectionId).firstOrNull;

    return TripCollection(
      id: row['id'].toString(),
      name: (row['name'] ?? '').toString(),
      description: row['description']?.toString(),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          current?.createdAt ??
          DateTime.now(),
      contentIds: current?.contentIds ?? const <String>[],
    );
  }

  @override
  Future<void> deleteCollection(String collectionId) {
    return _remote.deleteCollection(collectionId);
  }

  @override
  Future<void> addContentToCollection({
    required String collectionId,
    required String contentId,
  }) {
    return _remote.addContentToCollection(
      collectionId: collectionId,
      contentId: contentId,
    );
  }

  @override
  Future<void> removeContentFromCollection({
    required String collectionId,
    required String contentId,
  }) {
    return _remote.removeContentFromCollection(
      collectionId: collectionId,
      contentId: contentId,
    );
  }

  TripCollection _collectionFromRow(Map<String, dynamic> row) {
    final rawItems = row['trip_collection_items'];
    final ids = rawItems is List
        ? rawItems
            .map((item) => Map<String, dynamic>.from(item as Map))
            .map((item) => item['content_id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return TripCollection(
      id: row['id'].toString(),
      name: (row['name'] ?? '').toString(),
      description: row['description']?.toString(),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      contentIds: ids,
    );
  }
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
