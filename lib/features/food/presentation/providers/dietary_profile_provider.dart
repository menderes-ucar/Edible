import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/dietary_profile_storage.dart';
import '../../domain/entities/dietary_profile.dart';
import '../../domain/entities/food_filter.dart';

class DietaryProfileProvider extends ChangeNotifier {
  DietaryProfileProvider({
    DietaryProfileStorage storage = const DietaryProfileStorage(),
  }) : _storage = storage {
    unawaited(_restore());
  }

  final DietaryProfileStorage _storage;

  DietaryProfile _profile = const DietaryProfile();
  bool _isRestored = false;
  bool _touched = false;
  bool _disposed = false;

  DietaryProfile get profile => _profile;
  bool get isRestored => _isRestored;

  Future<void> toggleAllergen(Allergen allergen) {
    final next = {..._profile.allergens};
    if (!next.add(allergen)) next.remove(allergen);
    return _set(_profile.copyWith(allergens: next));
  }

  Future<void> toggleDiet(FoodFilter rule) {
    final next = {..._profile.diets};
    if (!next.add(rule)) next.remove(rule);
    return _set(_profile.copyWith(diets: next));
  }

  Future<void> clear() => _set(const DietaryProfile());

  Future<void> _restore() async {
    final stored = await _storage.read();
    if (_disposed) return;
    // If the user already changed something before the file was read, keep the
    // newer in-memory choices instead of overwriting them.
    if (stored != null && !_touched) {
      _profile = stored;
    }
    _isRestored = true;
    notifyListeners();
  }

  Future<void> _set(DietaryProfile next) async {
    if (_disposed) return;
    _touched = true;
    _profile = next;
    notifyListeners();
    await _storage.write(next);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
