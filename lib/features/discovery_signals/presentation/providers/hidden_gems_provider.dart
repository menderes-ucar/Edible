import 'package:flutter/foundation.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/hidden_gem_recommendation.dart';
import '../../domain/repositories/discovery_signals_repository.dart';
import '../../domain/services/hidden_gem_ranker.dart';

class HiddenGemsProvider extends ChangeNotifier {
  HiddenGemsProvider({
    required DiscoverySignalsRepository repository,
    HiddenGemRanker ranker = const HiddenGemRanker(),
  })  : _repository = repository,
        _ranker = ranker;

  final DiscoverySignalsRepository _repository;
  final HiddenGemRanker _ranker;

  List<HiddenGemRecommendation> _items = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _generation = 0;

  List<HiddenGemRecommendation> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> refresh({
    required List<ExploreContent> contents,
  }) async {
    final generation = ++_generation;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final affinitiesFuture = _repository.loadAffinities();
      final exposureFuture = _repository.loadContentExposure();

      final affinities = await affinitiesFuture;
      final exposure = await exposureFuture;
      if (generation != _generation) return;

      _items = _ranker.rank(
        contents: contents,
        affinities: affinities,
        exposure: exposure,
      );
    } catch (error) {
      if (generation != _generation) return;
      _errorMessage = error.toString();

      // Hidden Gems must degrade gracefully. With no exposure data, the
      // deterministic ranker treats catalog items as unknown rather than
      // breaking Explore.
      _items = _ranker.rank(
        contents: contents,
        affinities: const [],
        exposure: const [],
      );
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
