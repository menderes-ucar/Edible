import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/discovery_event.dart';
import '../../domain/repositories/discovery_signals_repository.dart';

class RecommendationFeedbackProvider extends ChangeNotifier {
  RecommendationFeedbackProvider({required DiscoverySignalsRepository repository}) : _repository = repository;
  final DiscoverySignalsRepository _repository;
  final Set<String> _notForMe = {}, _useful = {}, _pending = {};
  bool _disposed = false;
  int _generation = 0;
  bool isSuppressed(String id) => _notForMe.contains(id);
  bool isUseful(String id) => _useful.contains(id);
  bool isPending(String id) => _pending.contains(id);

  void useful({required String contentId, required String category, required String countryCode, required String cityName}) {
    if (_disposed || _pending.contains(contentId)) return;
    _useful.add(contentId); _notForMe.remove(contentId);
    _write(contentId, DiscoveryEvent(type: DiscoveryEventType.recommendationUseful, contentId: contentId, category: category, countryCode: countryCode, cityName: cityName));
  }

  void notForMe({required String contentId, required String category, required String countryCode, required String cityName}) {
    if (_disposed || _pending.contains(contentId)) return;
    _notForMe.add(contentId); _useful.remove(contentId); _notifyIfAlive();
    _write(contentId, DiscoveryEvent(type: DiscoveryEventType.recommendationNotForMe, contentId: contentId, category: category, countryCode: countryCode, cityName: cityName));
  }

  void _write(String id, DiscoveryEvent event) {
    if (_disposed) return;

    final generation = _generation;
    _pending.add(id);
    _notifyIfAlive();

    unawaited(
      _repository.record(event).catchError((_) {
        // Recommendation feedback must not break discovery UX.
      }).whenComplete(() {
        if (_disposed || generation != _generation) return;
        _pending.remove(id);
        _notifyIfAlive();
      }),
    );
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _pending.clear();
    super.dispose();
  }
}
