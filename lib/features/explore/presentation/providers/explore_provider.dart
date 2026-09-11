import 'package:flutter/foundation.dart';

import '../../domain/entities/explore_category.dart';
import '../../domain/entities/explore_content.dart';
import '../../domain/entities/explore_filters.dart';
import '../../domain/repositories/explore_repository.dart';

class ExploreProvider extends ChangeNotifier {
  ExploreProvider({
    required ExploreRepository repository,
  }) : _repository = repository;

  final ExploreRepository _repository;

  List<ExploreContent> _items = const [];
  ExploreCategory? _selectedCategory;
  String _query = '';
  ExploreFilters _filters = const ExploreFilters();
  bool _isLoading = false;
  bool _disposed = false;
  int _requestGeneration = 0;
  String? _errorMessage;
  String? _loadedLanguage;

  List<ExploreContent> get items => _items;
  ExploreCategory? get selectedCategory => _selectedCategory;
  String get query => _query;
  ExploreFilters get filters => _filters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ExploreContent> get visibleItems {
    final normalizedQuery = _query.trim().toLowerCase();

    final result = _items.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) return false;

      final country = _filters.countryCode?.trim().toUpperCase();
      if (country != null &&
          country.isNotEmpty &&
          item.countryCode.trim().toUpperCase() != country) {
        return false;
      }

      final city = _filters.cityName == null ? null : _normalizeCity(_filters.cityName!);
      if (city != null &&
          city.isNotEmpty &&
          _normalizeCity(item.cityName) != city) {
        return false;
      }

      if (_filters.featuredOnly && !item.isFeatured) return false;

      return normalizedQuery.isEmpty || _matches(item, normalizedQuery);
    }).toList();

    switch (_filters.sort) {
      case ExploreSort.recommended:
        result.sort((a, b) {
          final featured = (b.isFeatured ? 1 : 0).compareTo(
            a.isFeatured ? 1 : 0,
          );
          if (featured != 0) return featured;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      case ExploreSort.featuredFirst:
        result.sort((a, b) {
          final featured = (b.isFeatured ? 1 : 0).compareTo(
            a.isFeatured ? 1 : 0,
          );
          if (featured != 0) return featured;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      case ExploreSort.alphabetical:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }

    return result;
  }

  int get visibleCityCount =>
      visibleItems.map((item) => item.cityName.trim().toLowerCase()).where((value) => value.isNotEmpty).toSet().length;

  int get visibleCountryCount =>
      visibleItems.map((item) => item.countryCode.trim().toUpperCase()).where((value) => value.isNotEmpty).toSet().length;

  Map<String, String> get availableCountryNames {
    final result = <String, String>{};
    for (final item in _items) {
      final code = item.countryCode.trim().toUpperCase();
      final name = item.countryName.trim();
      if (code.isEmpty || name.isEmpty) continue;
      result.putIfAbsent(code, () => name);
    }
    return result;
  }

  List<String> get availableCountryCodes {
    final values = _items
        .map((item) => item.countryCode.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }


  Map<String, List<String>> get availableCitiesByCountry {
    final grouped = <String, Set<String>>{};

    for (final item in _items) {
      final country = item.countryCode.trim().toUpperCase();
      final city = item.cityName.trim();
      if (country.isEmpty || city.isEmpty) continue;
      grouped.putIfAbsent(country, () => <String>{}).add(city);
    }

    final result = <String, List<String>>{};
    for (final entry in grouped.entries) {
      final cities = entry.value.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      result[entry.key] = cities;
    }
    return result;
  }

  List<String> get availableCities {
    final country = _filters.countryCode?.trim().toUpperCase();

    final values = _items
        .where(
          (item) =>
              country == null ||
              country.isEmpty ||
              item.countryCode.trim().toUpperCase() == country,
        )
        .map((item) => item.cityName.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return values;
  }

  List<ExploreContent> get suggestions {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.length < 2) return const [];

    final unique = <String, ExploreContent>{};

    for (final item in _items) {
      if (_matches(item, normalizedQuery)) {
        final key = '${item.cityName}-${item.countryCode}-${item.title}';
        unique[key] = item;
      }
      if (unique.length >= 6) break;
    }

    return unique.values.toList();
  }

  bool _matches(ExploreContent item, String query) {
    return item.title.toLowerCase().contains(query) ||
        item.cityName.toLowerCase().contains(query) ||
        item.countryName.toLowerCase().contains(query) ||
        item.tags.any((tag) => tag.toLowerCase().contains(query));
  }

  Future<void> load({
    required String languageCode,
    bool force = false,
  }) async {
    if (_disposed) return;

    if (!force && _loadedLanguage == languageCode && _items.isNotEmpty) {
      return;
    }

    final generation = ++_requestGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final items = await _repository.getContents(
        languageCode: languageCode,
      );
      if (_disposed || generation != _requestGeneration) return;

      _items = items;
      _loadedLanguage = languageCode;
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

  void selectCategory(ExploreCategory category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _notifyIfAlive();
  }

  void updateFilters(ExploreFilters value) {
    if (_sameFilters(_filters, value)) return;
    _filters = value;
    _notifyIfAlive();
  }

  void clearFilters() {
    if (_filters.isEmpty) return;
    _filters = const ExploreFilters();
    _notifyIfAlive();
  }

  void clearCategory() {
    if (_selectedCategory == null) return;
    _selectedCategory = null;
    _notifyIfAlive();
  }

  String _normalizeCity(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  bool _sameFilters(ExploreFilters a, ExploreFilters b) {
    return a.countryCode == b.countryCode &&
        a.cityName == b.cityName &&
        a.featuredOnly == b.featuredOnly &&
        a.maxDistanceKm == b.maxDistanceKm &&
        a.sort == b.sort;
  }

  void updateQuery(String value) {
    final next = value.trim();
    if (_query == next) return;
    _query = next;
    _notifyIfAlive();
  }

  void selectSuggestion(ExploreContent item) {
    _query = item.cityName;
    _selectedCategory = item.category;
    _notifyIfAlive();
  }

  void clearQuery() {
    if (_query.isEmpty) return;
    _query = '';
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
