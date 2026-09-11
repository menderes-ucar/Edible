import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../../domain/entities/travel_memory.dart';
import '../../domain/entities/travel_memory_draft.dart';
import '../../domain/repositories/travel_journal_repository.dart';

class TravelMemoryProvider extends ChangeNotifier {
  TravelMemoryProvider({
    required TravelJournalRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _lastIdentity = _identity;
  }

  final TravelJournalRepository _repository;
  final AuthProvider _authProvider;

  TravelMemory? _memory;
  List<String> _photoPaths = const [];
  Map<String, String> _signedPhotoUrls = const {};
  final Set<String> _pendingPhotoDeletes = <String>{};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _loadedVisitId;
  int _loadGeneration = 0;
  int _mutationGeneration = 0;
  bool _disposed = false;
  String? _lastIdentity;

  TravelMemory? get memory => _memory;
  List<String> get photoPaths => _photoPaths;
  Map<String, String> get signedPhotoUrls => _signedPhotoUrls;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploading => _isUploading;
  bool isPhotoDeletePending(String storagePath) {
    return _pendingPhotoDeletes.contains(storagePath);
  }

  String? get errorMessage => _errorMessage;

  Future<void> load(String travelVisitId) async {
    if (_disposed) return;
    if (_loadedVisitId == travelVisitId && _memory != null) return;

    final generation = ++_loadGeneration;
    _loadedVisitId = travelVisitId;
    _isLoading = true;
    _errorMessage = null;
    _memory = null;
    _photoPaths = const [];
    _signedPhotoUrls = const {};
    _notifyIfAlive();

    try {
      final loaded = await _repository.getForVisit(travelVisitId);
      if (generation != _loadGeneration ||
          _loadedVisitId != travelVisitId) {
        return;
      }

      _memory = loaded;
      _photoPaths = [...?loaded?.photoPaths];

      final urls = await _signedUrlsFor(_photoPaths);
      if (generation != _loadGeneration ||
          _loadedVisitId != travelVisitId) {
        return;
      }

      _signedPhotoUrls = urls;
    } catch (error) {
      if (generation == _loadGeneration &&
          _loadedVisitId == travelVisitId) {
        _errorMessage = error.toString();
      }
    } finally {
      if (generation == _loadGeneration &&
          _loadedVisitId == travelVisitId) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> save(TravelMemoryDraft draft) async {
    if (_loadedVisitId != null &&
        _loadedVisitId != draft.travelVisitId) {
      _errorMessage = 'Travel memory session changed.';
      _notifyIfAlive();
      return false;
    }

    if (_isSaving || _isUploading) return false;

    _loadedVisitId = draft.travelVisitId;
    _isSaving = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      _memory = await _repository.save(
        TravelMemoryDraft(
          travelVisitId: draft.travelVisitId,
          countryCode: draft.countryCode,
          countryName: draft.countryName,
          cityName: draft.cityName,
          visitDate: draft.visitDate,
          title: draft.title,
          note: draft.note,
          favoriteFood: draft.favoriteFood,
          rating: draft.rating,
          mood: draft.mood,
          photoPaths: List.unmodifiable(_photoPaths),
        ),
      );
      _photoPaths = [..._memory!.photoPaths];
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isSaving = false;
      _notifyIfAlive();
    }
  }

  Future<String?> uploadPhoto({
    required String travelVisitId,
    required String filePath,
  }) async {
    if (_isSaving || _isUploading) return null;
    if (_loadedVisitId != null && _loadedVisitId != travelVisitId) {
      _errorMessage = 'Travel memory session changed.';
      _notifyIfAlive();
      return null;
    }

    _loadedVisitId = travelVisitId;
    _isUploading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final path = await _repository.uploadPhoto(
        travelVisitId: travelVisitId,
        filePath: filePath,
      );

      _photoPaths = [..._photoPaths, path];

      final signedUrl = await _repository.createSignedPhotoUrl(path);
      _signedPhotoUrls = {
        ..._signedPhotoUrls,
        path: signedUrl,
      };

      return path;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isUploading = false;
      _notifyIfAlive();
    }
  }

  Future<bool> removePhoto(String storagePath) async {
    if (_disposed || _authProvider.user == null) return false;
    if (_isSaving || _isUploading || _pendingPhotoDeletes.isNotEmpty) {
      return false;
    }

    final travelVisitId = _loadedVisitId;
    if (travelVisitId == null || !_photoPaths.contains(storagePath)) {
      return false;
    }

    final operationIdentity = _identity;
    final operationGeneration = _mutationGeneration;
    _errorMessage = null;
    _pendingPhotoDeletes.add(storagePath);
    _notifyIfAlive();

    final updatedPaths = _photoPaths
        .where((path) => path != storagePath)
        .toList(growable: false);

    try {
      final current = _memory;
      TravelMemory? savedMemory;

      // Persist the detached photo list before deleting Storage. This keeps
      // badge shine / journal state correct even if object cleanup later fails.
      if (current != null) {
        savedMemory = await _repository.save(
          TravelMemoryDraft(
            travelVisitId: current.travelVisitId,
            countryCode: current.countryCode,
            countryName: current.countryName,
            cityName: current.cityName,
            visitDate: current.visitDate,
            title: current.title,
            note: current.note,
            favoriteFood: current.favoriteFood,
            rating: current.rating,
            mood: current.mood,
            photoPaths: updatedPaths,
          ),
        );
      }

      if (!_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        travelVisitId: travelVisitId,
      )) {
        return false;
      }

      if (savedMemory != null) {
        _memory = savedMemory;
      }
      _photoPaths = updatedPaths;
      _signedPhotoUrls = {..._signedPhotoUrls}..remove(storagePath);
      _notifyIfAlive();

      try {
        await _repository.deletePhoto(storagePath);
      } catch (error) {
        if (_sameMutationSession(
          identity: operationIdentity,
          generation: operationGeneration,
          travelVisitId: travelVisitId,
        )) {
          _errorMessage = error.toString();
          _notifyIfAlive();
        }
      }

      return true;
    } catch (error) {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        travelVisitId: travelVisitId,
      )) {
        _errorMessage = error.toString();
        _notifyIfAlive();
      }
      return false;
    } finally {
      if (_sameMutationSession(
        identity: operationIdentity,
        generation: operationGeneration,
        travelVisitId: travelVisitId,
      )) {
        _pendingPhotoDeletes.remove(storagePath);
        _notifyIfAlive();
      }
    }
  }

  Future<Map<String, String>> _signedUrlsFor(
    List<String> paths,
  ) async {
    final entries = await Future.wait(
      paths.map((path) async {
        try {
          final url = await _repository.createSignedPhotoUrl(path);
          return MapEntry<String, String>(path, url);
        } catch (_) {
          return null;
        }
      }),
    );

    return {
      for (final entry in entries)
        if (entry != null) entry.key: entry.value,
    };
  }

  void clearError() {
    _errorMessage = null;
    _notifyIfAlive();
  }
  bool _sameMutationSession({
    required String identity,
    required int generation,
    required String travelVisitId,
  }) {
    return !_disposed &&
        _identity == identity &&
        _mutationGeneration == generation &&
        _loadedVisitId == travelVisitId;
  }

  String get _identity => _authProvider.user?.id ?? 'guest';

  void _handleAuthChanged() {
    final identity = _identity;
    if (_lastIdentity == identity) return;

    _lastIdentity = identity;
    _loadGeneration++;
    _mutationGeneration++;
    _loadedVisitId = null;
    _memory = null;
    _photoPaths = const [];
    _signedPhotoUrls = const {};
    _pendingPhotoDeletes.clear();
    _isLoading = false;
    _isSaving = false;
    _isUploading = false;
    _errorMessage = null;
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
    _loadGeneration++;
    _mutationGeneration++;
    _pendingPhotoDeletes.clear();
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }

}
