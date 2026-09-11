import 'package:flutter/foundation.dart';

import '../../../explore/domain/entities/explore_content.dart';
import '../../domain/entities/food_details.dart';
import '../../domain/entities/food_filter.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/usecases/filter_food_contents.dart';

class FoodFilterProvider extends ChangeNotifier {
  FoodFilterProvider({
    required FoodRepository repository,
    FilterFoodContents filterFoodContents = const FilterFoodContents(),
  })  : _repository = repository,
        _filterFoodContents = filterFoodContents;

  final FoodRepository _repository;
  final FilterFoodContents _filterFoodContents;

  final Set<FoodFilter> _filters = {};
  Map<String, FoodDetails> _details = const {};
  String? _loadedLanguageCode;
  Set<String> _loadedIds = const {};
  bool _isLoading = false;
  String? _loadingLanguageCode;
  Set<String> _loadingIds = const {};
  String? _errorMessage;
  int _requestGeneration = 0;
  bool _disposed = false;

  Set<FoodFilter> get filters => Set.unmodifiable(_filters);
  Map<String, FoodDetails> get details => _details;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isSelected(FoodFilter filter) => _filters.contains(filter);

  Future<void> ensureLoaded({
    required Iterable<ExploreContent> contents,
    required String languageCode,
  }) async {
    if (_disposed) return;

    final foodContents = contents.where(_isFoodContent).toList(growable: false);
    final ids = foodContents.map((item) => item.id).toSet();

    if (_loadedLanguageCode == languageCode &&
        setEquals(_loadedIds, ids)) {
      return;
    }

    if (_isLoading &&
        _loadingLanguageCode == languageCode &&
        setEquals(_loadingIds, ids)) {
      return;
    }

    final generation = ++_requestGeneration;

    _isLoading = true;
    _loadingLanguageCode = languageCode;
    _loadingIds = ids;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final details = await _repository.getDetailsForContents(
        contentIds: ids,
        languageCode: languageCode,
      );

      if (!_isCurrentRequest(
        generation: generation,
        languageCode: languageCode,
        ids: ids,
      )) {
        return;
      }

      _details = details;
      _loadedIds = Set.unmodifiable(ids);
      _loadedLanguageCode = languageCode;
    } catch (error) {
      if (!_isCurrentRequest(
        generation: generation,
        languageCode: languageCode,
        ids: ids,
      )) {
        return;
      }

      _errorMessage = error.toString();
    } finally {
      if (_isCurrentRequest(
        generation: generation,
        languageCode: languageCode,
        ids: ids,
      )) {
        _isLoading = false;
        _loadingLanguageCode = null;
        _loadingIds = const {};
        _notifyIfAlive();
      }
    }
  }

  void toggle(FoodFilter filter) {
    if (_disposed) return;

    if (!_filters.add(filter)) {
      _filters.remove(filter);
    }
    _notifyIfAlive();
  }

  void clear() {
    if (_disposed || _filters.isEmpty) return;
    _filters.clear();
    _notifyIfAlive();
  }

  List<ExploreContent> apply(Iterable<ExploreContent> contents) {
    return _filterFoodContents(
      contents: contents,
      detailsByContentId: _details,
      filters: _filters,
    );
  }


  bool _isCurrentRequest({
    required int generation,
    required String languageCode,
    required Set<String> ids,
  }) {
    return !_disposed &&
        generation == _requestGeneration &&
        _loadingLanguageCode == languageCode &&
        setEquals(_loadingIds, ids);
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
    _loadingLanguageCode = null;
    _loadingIds = const {};
    super.dispose();
  }

  bool _isFoodContent(ExploreContent item) {
    final name = item.category.name;
    return name == 'food' ||
        name == 'snack' ||
        name == 'fruit' ||
        name == 'drink';
  }
}
