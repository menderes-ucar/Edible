import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/progress_remote_data_source.dart';
import '../../domain/entities/content_progress.dart';
import '../../domain/entities/trip_collection.dart';
import '../../domain/repositories/progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({
    required ProgressRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _auth = authProvider {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final ProgressRepository _repository;
  final AuthProvider _auth;

  Set<String> _visited = <String>{};
  Set<String> _tried = <String>{};
  List<TripCollection> _collections = const <TripCollection>[];

  final Set<String> _pendingProgress = <String>{};
  final Set<String> _pendingCollections = <String>{};

  bool _loading = false;
  String? _error;
  String? _loadedUserId;
  int _requestGeneration = 0;
  bool _disposed = false;

  Set<String> get visitedIds => Set<String>.unmodifiable(_visited);
  Set<String> get triedIds => Set<String>.unmodifiable(_tried);
  List<TripCollection> get collections =>
      List<TripCollection>.unmodifiable(_collections);

  bool get isLoading => _loading;
  String? get errorMessage => _error;
  bool get hasError => _error != null;

  String? get errorCode {
    final message = _error ?? '';
    if (message.contains('content_not_synced_to_supabase')) {
      return 'content_not_synced_to_supabase';
    }
    if (message.contains('Authentication required')) {
      return 'authentication_required';
    }
    return _error == null ? null : 'progress_persistence_failed';
  }

  int get visitedCount => _visited.length;
  int get triedCount => _tried.length;

  bool isVisited(String id) => _visited.contains(id);
  bool isTried(String id) => _tried.contains(id);

  bool isProgressPending({
    required String contentId,
    required ContentProgressType type,
  }) {
    return _pendingProgress.contains('${type.value}:$contentId');
  }

  bool isVisitedPending(String contentId) {
    return isProgressPending(
      contentId: contentId,
      type: ContentProgressType.visited,
    );
  }

  bool isTriedPending(String contentId) {
    return isProgressPending(
      contentId: contentId,
      type: ContentProgressType.tried,
    );
  }

  bool isCollectionPending(String collectionId) {
    return _pendingCollections.contains(collectionId);
  }

  bool isCollectionItemPending({
    required String collectionId,
    required String contentId,
  }) {
    return _pendingCollections.contains('$collectionId:$contentId');
  }

  TripCollection? collectionById(String id) {
    for (final collection in _collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  Future<void> _onAuthChanged() async {
    if (_disposed) return;

    final userId = _auth.user?.id;
    if (_loadedUserId == userId) return;

    _requestGeneration++;
    _loadedUserId = userId;
    _pendingProgress.clear();
    _pendingCollections.clear();

    if (userId == null) {
      _visited = <String>{};
      _tried = <String>{};
      _collections = const <TripCollection>[];
      _loading = false;
      _error = null;
      _notifyIfAlive();
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed || _auth.isGuest) return;

    final requestId = ++_requestGeneration;
    final userId = _auth.user?.id;

    _loading = true;
    _error = null;
    _notifyIfAlive();

    try {
      final results = await Future.wait<Object>([
        _repository.getVisitedIds(),
        _repository.getTriedIds(),
        _repository.getCollections(),
      ]);

      if (_disposed ||
          requestId != _requestGeneration ||
          userId != _auth.user?.id) {
        return;
      }

      _visited = Set<String>.from(results[0] as Set<String>);
      _tried = Set<String>.from(results[1] as Set<String>);
      _collections = List<TripCollection>.from(
        results[2] as List<TripCollection>,
      );
    } catch (error) {
      if (!_disposed && requestId == _requestGeneration) {
        _error = error.toString();
      }
    } finally {
      if (!_disposed && requestId == _requestGeneration) {
        _loading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> toggleVisited(String id) {
    return _toggle(id, ContentProgressType.visited);
  }

  Future<bool> toggleTried(String id) {
    return _toggle(id, ContentProgressType.tried);
  }

  Future<bool> _toggle(
    String id,
    ContentProgressType type,
  ) async {
    if (_disposed) return false;

    final operationUserId = _auth.user?.id;
    if (operationUserId == null) {
      _error = 'Authentication required.';
      _notifyIfAlive();
      return false;
    }

    final key = '${type.value}:$id';
    if (_pendingProgress.contains(key)) return false;

    final operationGeneration = _requestGeneration;
    final target = type == ContentProgressType.visited ? _visited : _tried;
    final enable = !target.contains(id);

    _pendingProgress.add(key);
    _error = null;

    if (enable) {
      target.add(id);
    } else {
      target.remove(id);
    }
    _notifyIfAlive();

    try {
      await _repository.setProgress(
        contentId: id,
        type: type,
        enabled: enable,
      );

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      return true;
    } catch (error) {
      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      if (enable) {
        target.remove(id);
      } else {
        target.add(id);
      }
      _error = error.toString();
      _notifyIfAlive();
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingProgress.remove(key);
        _notifyIfAlive();
      }
    }
  }

  bool _sameOperationSession({
    required String userId,
    required int generation,
  }) {
    return !_disposed &&
        _auth.user?.id == userId &&
        _requestGeneration == generation;
  }

  Future<TripCollection?> createCollection({
    required String name,
    String? description,
  }) async {
    if (_disposed) return null;

    final normalizedName = name.trim();
    if (_auth.isGuest || normalizedName.isEmpty || normalizedName.length > 100) {
      _error = 'Invalid collection name.';
      _notifyIfAlive();
      return null;
    }

    const pendingKey = '__create__';
    if (_pendingCollections.contains(pendingKey)) return null;

    _pendingCollections.add(pendingKey);
    _error = null;
    _notifyIfAlive();

    final operationUserId = _auth.user?.id;
    final operationGeneration = _requestGeneration;

    try {
      final collection = await _repository.createCollection(
        name: normalizedName,
        description: description,
      );

      if (operationUserId == null ||
          !_sameOperationSession(
            userId: operationUserId,
            generation: operationGeneration,
          )) {
        return null;
      }

      _collections = <TripCollection>[collection, ..._collections];
      _notifyIfAlive();
      return collection;
    } catch (error) {
      if (operationUserId != null &&
          _sameOperationSession(
            userId: operationUserId,
            generation: operationGeneration,
          )) {
        _error = error.toString();
        _notifyIfAlive();
      }
      return null;
    } finally {
      if (operationUserId != null &&
          _sameOperationSession(
            userId: operationUserId,
            generation: operationGeneration,
          )) {
        _pendingCollections.remove(pendingKey);
        _notifyIfAlive();
      }
    }
  }

  Future<bool> updateCollection({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    if (_disposed) return false;

    final operationUserId = _auth.user?.id;
    if (operationUserId == null) {
      _error = 'Authentication required.';
      _notifyIfAlive();
      return false;
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty || normalizedName.length > 100) {
      _error = 'Invalid collection name.';
      _notifyIfAlive();
      return false;
    }

    if (_pendingCollections.contains(collectionId)) return false;

    final operationGeneration = _requestGeneration;
    _pendingCollections.add(collectionId);
    _error = null;
    _notifyIfAlive();

    try {
      final updated = await _repository.updateCollection(
        collectionId: collectionId,
        name: normalizedName,
        description: description,
      );

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      final current = collectionById(collectionId);
      final merged = TripCollection(
        id: updated.id,
        name: updated.name,
        description: updated.description,
        createdAt: current?.createdAt ?? updated.createdAt,
        contentIds: current?.contentIds ?? updated.contentIds,
      );

      _collections = [
        for (final item in _collections)
          if (item.id == collectionId) merged else item,
      ];
      _notifyIfAlive();
      return true;
    } catch (error) {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _error = error.toString();
        _notifyIfAlive();
      }
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingCollections.remove(collectionId);
        _notifyIfAlive();
      }
    }
  }

  Future<bool> deleteCollection(String collectionId) async {
    if (_disposed) return false;

    final operationUserId = _auth.user?.id;
    if (operationUserId == null) {
      _error = 'Authentication required.';
      _notifyIfAlive();
      return false;
    }

    if (_pendingCollections.contains(collectionId)) return false;

    final existing = collectionById(collectionId);
    if (existing == null) return false;

    final operationGeneration = _requestGeneration;
    _pendingCollections.add(collectionId);
    _error = null;
    _collections =
        _collections.where((item) => item.id != collectionId).toList();
    _notifyIfAlive();

    try {
      await _repository.deleteCollection(collectionId);

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      return true;
    } catch (error) {
      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      _collections = <TripCollection>[existing, ..._collections]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _error = error.toString();
      _notifyIfAlive();
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingCollections.remove(collectionId);
        _notifyIfAlive();
      }
    }
  }

  Future<bool> toggleCollectionItem({
    required String collectionId,
    required String contentId,
  }) async {
    if (_disposed) return false;

    final operationUserId = _auth.user?.id;
    if (operationUserId == null) {
      _error = 'Authentication required.';
      _notifyIfAlive();
      return false;
    }

    final index = _collections.indexWhere((item) => item.id == collectionId);
    if (index < 0) return false;

    final operationKey = '$collectionId:$contentId';
    if (_pendingCollections.contains(operationKey)) return false;

    final operationGeneration = _requestGeneration;
    final collection = _collections[index];
    final ids = List<String>.from(collection.contentIds);
    final hadContent = ids.contains(contentId);

    _pendingCollections.add(operationKey);
    _error = null;

    if (hadContent) {
      ids.remove(contentId);
    } else {
      ids.add(contentId);
    }
    _replaceCollection(collection, ids);
    _notifyIfAlive();

    try {
      if (hadContent) {
        await _repository.removeContentFromCollection(
          collectionId: collectionId,
          contentId: contentId,
        );
      } else {
        await _repository.addContentToCollection(
          collectionId: collectionId,
          contentId: contentId,
        );
      }

      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      return true;
    } catch (error) {
      if (!_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        return false;
      }

      final rollbackIds = List<String>.from(ids);
      if (hadContent) {
        rollbackIds.add(contentId);
      } else {
        rollbackIds.remove(contentId);
      }
      _replaceCollection(collection, rollbackIds);
      _error = error.toString();
      _notifyIfAlive();
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingCollections.remove(operationKey);
        _notifyIfAlive();
      }
    }
  }

  void clearError() {
    if (_disposed || _error == null) return;
    _error = null;
    _notifyIfAlive();
  }

  void _replaceCollection(
    TripCollection source,
    List<String> contentIds,
  ) {
    if (_disposed) return;

    final updated = TripCollection(
      id: source.id,
      name: source.name,
      description: source.description,
      createdAt: source.createdAt,
      contentIds: List<String>.unmodifiable(contentIds),
    );

    _collections = [
      for (final item in _collections)
        if (item.id == source.id) updated else item,
    ];
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    _loading = false;
    _pendingProgress.clear();
    _pendingCollections.clear();
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
