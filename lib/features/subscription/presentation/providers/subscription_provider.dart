import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/subscription_entitlement.dart';
import '../../domain/repositories/subscription_repository.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider({
    required SubscriptionRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final SubscriptionRepository _repository;
  final AuthProvider _authProvider;

  SubscriptionEntitlement _entitlement = SubscriptionEntitlement.free;
  bool _isLoading = false;
  String? _loadedUserId;
  int _requestGeneration = 0;
  bool _disposed = false;

  SubscriptionEntitlement get entitlement => _entitlement;
  bool get isLoading => _isLoading;
  bool get isPremium => _entitlement.isPremium;

  bool canUse(PremiumFeature feature) => _entitlement.canUse(feature);

  Future<void> _handleAuthChanged() async {
    if (_disposed) return;

    final user = _authProvider.user;
    _requestGeneration++;

    if (user == null) {
      _loadedUserId = null;
      _isLoading = false;
      _entitlement = SubscriptionEntitlement.free;
      _notifyIfAlive();
      return;
    }

    if (_loadedUserId == user.id) return;
    _loadedUserId = user.id;
    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;

    final userId = _authProvider.user?.id;
    if (userId == null) {
      _entitlement = SubscriptionEntitlement.free;
      _isLoading = false;
      _notifyIfAlive();
      return;
    }

    final generation = ++_requestGeneration;
    _isLoading = true;
    _notifyIfAlive();

    try {
      final entitlement = await _repository.getCurrentEntitlement();

      if (!_sameSession(
        userId: userId,
        generation: generation,
      )) {
        return;
      }

      _entitlement = entitlement;
    } finally {
      if (_sameSession(
        userId: userId,
        generation: generation,
      )) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void applyClientEntitlement({
    required String userId,
    required SubscriptionEntitlement entitlement,
  }) {
    if (_disposed || _authProvider.user?.id != userId) return;

    _entitlement = entitlement;
    _loadedUserId = userId;
    notifyListeners();
  }

  bool _sameSession({
    required String userId,
    required int generation,
  }) {
    return !_disposed &&
        _authProvider.user?.id == userId &&
        _requestGeneration == generation;
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
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
