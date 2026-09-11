import 'package:flutter/foundation.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/discovery_affinity.dart';
import '../../domain/entities/for_you_recommendation.dart';
import '../../domain/repositories/discovery_signals_repository.dart';
import '../../domain/services/for_you_ranker.dart';

class ForYouProvider extends ChangeNotifier {
  ForYouProvider({
    required DiscoverySignalsRepository repository,
    ForYouRanker ranker = const ForYouRanker(),
  })  : _repository = repository,
        _ranker = ranker;

  final DiscoverySignalsRepository _repository;
  final ForYouRanker _ranker;

  List<DiscoveryAffinity> _affinities = const [];
  List<ForYouRecommendation> _recommendations = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;

  List<DiscoveryAffinity> get affinities => _affinities;
  List<ForYouRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPersonalSignals => _affinities.any((item) => item.signalScore > 0);

  Future<void> refresh({
    required List<ExploreContent> contents,
  }) async {
    if (_disposed) return;

    final generation = ++_generation;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final affinities = await _repository.loadAffinities();
      if (!_isCurrent(generation)) return;

      _affinities = affinities;
      _recommendations = _ranker.rank(
        contents: contents,
        affinities: affinities,
      );
    } catch (error) {
      if (!_isCurrent(generation)) return;
      _errorMessage = error.toString();

      // Personalization failure must degrade to deterministic catalog fallback.
      _affinities = const [];
      _recommendations = _ranker.rank(
        contents: contents,
        affinities: const [],
      );
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void invalidate() {
    if (_disposed) return;

    _generation++;
    _affinities = const [];
    _recommendations = const [];
    _errorMessage = null;
    _isLoading = false;
    _notifyIfAlive();
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
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
    _isLoading = false;
    super.dispose();
  }
}
