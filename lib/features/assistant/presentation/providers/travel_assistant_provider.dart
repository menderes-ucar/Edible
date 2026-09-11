import 'package:flutter/foundation.dart';

import '../../domain/entities/travel_assistant_request.dart';
import '../../domain/entities/travel_assistant_response.dart';
import '../../domain/repositories/travel_assistant_repository.dart';

class TravelAssistantProvider extends ChangeNotifier {
  TravelAssistantProvider({
    required TravelAssistantRepository repository,
  }) : _repository = repository;

  final TravelAssistantRepository _repository;

  TravelAssistantResponse? _response;
  bool _isLoading = false;
  String? _errorMessage;
  int _requestGeneration = 0;
  bool _disposed = false;

  TravelAssistantResponse? get response => _response;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> ask({
    required String message,
    required String languageCode,
    String? defaultCityName,
  }) async {
    if (_disposed || message.trim().isEmpty) return;

    final generation = ++_requestGeneration;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final response = await _repository.ask(
        TravelAssistantRequest(
          message: message,
          languageCode: languageCode,
          defaultCityName: defaultCityName,
        ),
      );

      if (!_isCurrent(generation)) return;
      _response = response;
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _errorMessage = error.toString();
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void clear() {
    if (_disposed) return;

    _requestGeneration++;
    _response = null;
    _errorMessage = null;
    _isLoading = false;
    _notifyIfAlive();
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _requestGeneration;
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
