import 'package:flutter/foundation.dart';

import '../../domain/entities/offline_city_pack.dart';
import '../../domain/repositories/offline_city_pack_repository.dart';

class OfflineCityPackProvider extends ChangeNotifier {
  OfflineCityPackProvider({
    required OfflineCityPackRepository repository,
  }) : _repository = repository;

  final OfflineCityPackRepository _repository;

  List<OfflineCityPack> _packs = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _refreshGeneration = 0;
  int _mutationGeneration = 0;
  bool _disposed = false;
  final Set<String> _pendingKeys = <String>{};

  List<OfflineCityPack> get packs =>
      List<OfflineCityPack>.unmodifiable(_packs);
  bool get isLoading => _isLoading;
  bool get hasPendingOperations => _pendingKeys.isNotEmpty;
  String? get errorMessage => _errorMessage;

  bool isPending({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) {
    return _pendingKeys.contains(
      _key(
        countryCode: countryCode,
        cityName: cityName,
        languageCode: languageCode,
      ),
    );
  }

  Future<void> ensureLoaded() async {
    if (_disposed || _isLoading || _packs.isNotEmpty) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;

    final generation = ++_refreshGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final packs = await _repository.getAll();
      if (!_isCurrentRefresh(generation)) return;
      _packs = packs;
    } catch (error) {
      if (!_isCurrentRefresh(generation)) return;
      _errorMessage = error.toString();
    } finally {
      if (_isCurrentRefresh(generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  bool contains({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) {
    return _packs.any(
      (pack) =>
          pack.countryCode.toLowerCase() == countryCode.toLowerCase() &&
          pack.cityName.toLowerCase() == cityName.toLowerCase() &&
          pack.languageCode.toLowerCase() == languageCode.toLowerCase(),
    );
  }

  Future<bool> download({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    if (_disposed) return false;

    final operationGeneration = _mutationGeneration;
    final key = _key(
      countryCode: countryCode,
      cityName: cityName,
      languageCode: languageCode,
    );
    if (_pendingKeys.contains(key)) return false;

    _pendingKeys.add(key);
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await _repository.download(
        countryCode: countryCode,
        cityName: cityName,
        languageCode: languageCode,
      );

      if (!_isCurrentMutation(operationGeneration)) return false;

      _refreshGeneration++;
      final packs = await _repository.getAll();

      if (!_isCurrentMutation(operationGeneration)) return false;

      _packs = packs;
      return true;
    } catch (error) {
      if (_isCurrentMutation(operationGeneration)) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_isCurrentMutation(operationGeneration)) {
        _pendingKeys.remove(key);
        _notifyIfAlive();
      }
    }
  }

  Future<bool> delete(OfflineCityPack pack) async {
    if (_disposed) return false;

    final operationGeneration = _mutationGeneration;
    final key = _key(
      countryCode: pack.countryCode,
      cityName: pack.cityName,
      languageCode: pack.languageCode,
    );
    if (_pendingKeys.contains(key)) return false;

    _pendingKeys.add(key);
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await _repository.delete(
        countryCode: pack.countryCode,
        cityName: pack.cityName,
        languageCode: pack.languageCode,
      );

      if (!_isCurrentMutation(operationGeneration)) return false;

      _refreshGeneration++;
      final packs = await _repository.getAll();

      if (!_isCurrentMutation(operationGeneration)) return false;

      _packs = packs;
      return true;
    } catch (error) {
      if (_isCurrentMutation(operationGeneration)) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_isCurrentMutation(operationGeneration)) {
        _pendingKeys.remove(key);
        _notifyIfAlive();
      }
    }
  }

  String _key({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) {
    return '${countryCode.trim().toLowerCase()}|'
        '${cityName.trim().toLowerCase()}|'
        '${languageCode.trim().toLowerCase()}';
  }

  bool _isCurrentRefresh(int generation) {
    return !_disposed && generation == _refreshGeneration;
  }

  bool _isCurrentMutation(int generation) {
    return !_disposed && generation == _mutationGeneration;
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshGeneration++;
    _mutationGeneration++;
    _isLoading = false;
    _pendingKeys.clear();
    super.dispose();
  }

}
