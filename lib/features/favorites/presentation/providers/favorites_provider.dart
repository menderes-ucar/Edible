import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../explore/domain/entities/explore_content.dart';
import '../../../explore/domain/repositories/explore_repository.dart';
import '../../data/datasources/favorite_remote_data_source.dart';
import '../../domain/repositories/favorite_repository.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({
    required FavoriteRepository repository,
    required ExploreRepository exploreRepository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _exploreRepository = exploreRepository,
        _authProvider = authProvider {
    _lastUserId = _authProvider.user?.id;
    _authProvider.addListener(_handleAuthChanged);
  }

  final FavoriteRepository _repository;
  final ExploreRepository _exploreRepository;
  final AuthProvider _authProvider;

  Set<String> _favoriteIds = <String>{};
  List<ExploreContent> _items = const <ExploreContent>[];
  final Set<String> _pendingIds = <String>{};

  bool _isLoading = false;
  String? _errorMessage;
  String? _loadedLanguageCode;
  String? _lastUserId;
  int _requestGeneration = 0;
  bool _disposed = false;

  Set<String> get favoriteIds => Set<String>.unmodifiable(_favoriteIds);
  List<ExploreContent> get items => List<ExploreContent>.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  String? get errorCode {
    final message = _errorMessage ?? '';
    if (message.contains('content_not_synced_to_supabase')) {
      return 'content_not_synced_to_supabase';
    }
    if (message.contains('authentication_required')) {
      return 'authentication_required';
    }
    return _errorMessage == null ? null : 'favorite_persistence_failed';
  }

  bool isFavorite(String contentId) => _favoriteIds.contains(contentId);
  bool isPending(String contentId) => _pendingIds.contains(contentId);

  Future<void> ensureLoaded({
    required String languageCode,
  }) async {
    if (_disposed) return;

    if (!_authProvider.isAuthenticated) {
      _clearForGuest();
      return;
    }

    final currentUserId = _authProvider.user?.id;
    final alreadyLoaded =
        _loadedLanguageCode == languageCode &&
        _lastUserId == currentUserId &&
        !_isLoading;

    if (alreadyLoaded) {
      return;
    }

    await refresh(languageCode: languageCode);
  }

  Future<void> refresh({
    required String languageCode,
  }) async {
    if (_disposed) return;

    if (!_authProvider.isAuthenticated) {
      _clearForGuest();
      return;
    }

    final requestId = ++_requestGeneration;
    final userId = _authProvider.user?.id;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final ids = await _repository.getFavoriteIds();
      final allContents = await _exploreRepository.getContents(
        languageCode: languageCode,
      );

      if (_disposed ||
          requestId != _requestGeneration ||
          userId != _authProvider.user?.id) {
        return;
      }

      _favoriteIds = Set<String>.from(ids);
      _items = allContents
          .where((content) => ids.contains(content.id))
          .toList(growable: false);

      _loadedLanguageCode = languageCode;
      _lastUserId = userId;
    } catch (error) {
      if (!_disposed && requestId == _requestGeneration) {
        _errorMessage = error.toString();
      }
    } finally {
      if (!_disposed && requestId == _requestGeneration) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> toggle(ExploreContent content) async {
    if (_disposed) return false;

    final operationUserId = _authProvider.user?.id;
    if (operationUserId == null) {
      _errorMessage = 'Authentication required.';
      _notifyIfAlive();
      return false;
    }

    if (_pendingIds.contains(content.id)) {
      return false;
    }

    final operationGeneration = _requestGeneration;
    final wasFavorite = _favoriteIds.contains(content.id);

    _pendingIds.add(content.id);
    _errorMessage = null;

    if (wasFavorite) {
      _favoriteIds.remove(content.id);
      _items = _items
          .where((item) => item.id != content.id)
          .toList(growable: false);
    } else {
      _favoriteIds.add(content.id);
      if (!_items.any((item) => item.id == content.id)) {
        _items = <ExploreContent>[..._items, content];
      }
    }

    _notifyIfAlive();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(content.id);
      } else {
        await _repository.addFavorite(content.id);
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

      if (wasFavorite) {
        _favoriteIds.add(content.id);
        if (!_items.any((item) => item.id == content.id)) {
          _items = <ExploreContent>[..._items, content];
        }
      } else {
        _favoriteIds.remove(content.id);
        _items = _items
            .where((item) => item.id != content.id)
            .toList(growable: false);
      }

      _errorMessage = error.toString();
      _notifyIfAlive();
      return false;
    } finally {
      if (_sameOperationSession(
        userId: operationUserId,
        generation: operationGeneration,
      )) {
        _pendingIds.remove(content.id);
        _notifyIfAlive();
      }
    }
  }

  bool _sameOperationSession({
    required String userId,
    required int generation,
  }) {
    return !_disposed &&
        _authProvider.user?.id == userId &&
        _requestGeneration == generation;
  }

  void clearError() {
    if (_disposed || _errorMessage == null) {
      return;
    }

    _errorMessage = null;
    _notifyIfAlive();
  }

  void _handleAuthChanged() {
    if (_disposed) return;

    final currentUserId = _authProvider.user?.id;
    if (currentUserId == _lastUserId) {
      return;
    }

    _requestGeneration++;
    _lastUserId = currentUserId;
    _loadedLanguageCode = null;
    _favoriteIds = <String>{};
    _items = const <ExploreContent>[];
    _pendingIds.clear();
    _errorMessage = null;
    _isLoading = false;
    _notifyIfAlive();
  }

  void _clearForGuest() {
    if (_disposed) return;

    _requestGeneration++;
    _favoriteIds = <String>{};
    _items = const <ExploreContent>[];
    _pendingIds.clear();
    _loadedLanguageCode = null;
    _lastUserId = null;
    _errorMessage = null;
    _isLoading = false;
    _notifyIfAlive();
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
    _isLoading = false;
    _pendingIds.clear();
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
