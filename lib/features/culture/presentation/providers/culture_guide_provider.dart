import 'package:flutter/foundation.dart';

import '../../domain/entities/culture_guide.dart';
import '../../domain/repositories/culture_repository.dart';

class CultureGuideProvider extends ChangeNotifier {
  CultureGuideProvider({
    required CultureRepository repository,
  }) : _repository = repository;

  final CultureRepository _repository;

  CultureGuide? _guide;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestGeneration = 0;
  bool _disposed = false;
  String? _cacheKey;

  CultureGuide? get guide => _guide;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load({
    required String countryCode,
    required String cityName,
    required String languageCode,
  }) async {
    if (_disposed) return;

    final key = '$countryCode|$cityName|$languageCode';
    if (_cacheKey == key && _guide != null) return;

    final generation = ++_requestGeneration;

    _cacheKey = key;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final guide = await _repository.getGuide(
        countryCode: countryCode,
        cityName: cityName,
        languageCode: languageCode,
      );
      if (_disposed || generation != _requestGeneration) return;
      _guide = guide;
    } catch (error) {
      if (_disposed || generation != _requestGeneration) return;
      _errorMessage = error.toString();
    } finally {
      if (!_disposed && generation == _requestGeneration) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void clear() {
    if (_disposed) return;

    _requestGeneration++;
    _cacheKey = null;
    _guide = null;
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
    _requestGeneration++;
    _isLoading = false;
    super.dispose();
  }

}
