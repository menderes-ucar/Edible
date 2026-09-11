import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/revenuecat_service.dart';
import '../../domain/entities/purchase_option.dart';
import '../../domain/entities/subscription_entitlement.dart';
import '../../domain/repositories/purchase_repository.dart';
import 'subscription_provider.dart';

class PurchaseProvider extends ChangeNotifier {
  PurchaseProvider({
    required PurchaseRepository repository,
    required AuthProvider authProvider,
    required SubscriptionProvider subscriptionProvider,
  })  : _repository = repository,
        _authProvider = authProvider,
        _subscriptionProvider = subscriptionProvider {
    _authProvider.addListener(_handleAuthChanged);
    _entitlementSubscription = _repository.entitlementChanges.listen(
      _handleEntitlementChanged,
    );
    _handleAuthChanged();
  }

  final PurchaseRepository _repository;
  final AuthProvider _authProvider;
  final SubscriptionProvider _subscriptionProvider;

  List<PurchaseOption> _options = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _identifiedUserId;
  int _authGeneration = 0;
  StreamSubscription<SubscriptionEntitlement>? _entitlementSubscription;
  bool _disposed = false;

  List<PurchaseOption> get options => _options;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _handleAuthChanged() async {
    if (_disposed) return;

    final user = _authProvider.user;
    final generation = ++_authGeneration;

    if (user == null) {
      _identifiedUserId = null;
      _options = const [];
      _isLoading = false;
      _errorMessage = null;
      _notifyIfAlive();

      try {
        await _repository.logOut();
      } catch (_) {
        // App auth must still be able to log out even if RevenueCat is
        // temporarily unavailable.
      }
      return;
    }

    if (_identifiedUserId == user.id) return;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final entitlement = await _repository.identify(user.id);

      if (!_sameAuthSession(user.id, generation)) return;

      _identifiedUserId = user.id;

      if (entitlement != null) {
        _subscriptionProvider.applyClientEntitlement(
          userId: user.id,
          entitlement: entitlement,
        );
      }

      await _subscriptionProvider.refresh();
      if (!_sameAuthSession(user.id, generation)) return;

      final options = await _repository.getOptions();
      if (!_sameAuthSession(user.id, generation)) return;
      _options = options;
    } catch (error) {
      if (_sameAuthSession(user.id, generation)) {
        _errorMessage = error.toString();
      }
    } finally {
      if (_sameAuthSession(user.id, generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void _handleEntitlementChanged(SubscriptionEntitlement entitlement) {
    if (_disposed) return;

    final userId = _authProvider.user?.id;
    if (userId == null || _identifiedUserId != userId) return;

    _subscriptionProvider.applyClientEntitlement(
      userId: userId,
      entitlement: entitlement,
    );
  }

  bool _sameAuthSession(String userId, int generation) {
    return !_disposed &&
        _authProvider.user?.id == userId &&
        _authGeneration == generation;
  }

  Future<void> loadOptions() async {
    if (_disposed) return;

    final userId = _authProvider.user?.id;
    if (userId == null || _isLoading) return;

    final generation = _authGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final options = await _repository.getOptions();
      if (_sameAuthSession(userId, generation)) {
        _options = options;
      }
    } catch (error) {
      if (_sameAuthSession(userId, generation)) {
        _errorMessage = error.toString();
      }
    } finally {
      if (_sameAuthSession(userId, generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> purchase(PurchaseOption option) async {
    if (_disposed) return false;

    final userId = _authProvider.user?.id;
    if (userId == null || _isLoading) return false;

    final generation = _authGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final entitlement =
          await _repository.purchase(option.packageIdentifier);

      if (!_sameAuthSession(userId, generation)) return false;

      _subscriptionProvider.applyClientEntitlement(
        userId: userId,
        entitlement: entitlement,
      );

      // Refresh reconciles RevenueCat's immediate result with the server-side
      // subscription row/webhook state without delaying local activation.
      await _subscriptionProvider.refresh();
      return _sameAuthSession(userId, generation) &&
          _subscriptionProvider.isPremium;
    } on PurchaseCancelledException {
      return false;
    } catch (error) {
      if (_sameAuthSession(userId, generation)) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameAuthSession(userId, generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<bool> restore() async {
    if (_disposed) return false;

    final userId = _authProvider.user?.id;
    if (userId == null || _isLoading) return false;

    final generation = _authGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final entitlement = await _repository.restore();

      if (!_sameAuthSession(userId, generation)) return false;

      _subscriptionProvider.applyClientEntitlement(
        userId: userId,
        entitlement: entitlement,
      );

      await _subscriptionProvider.refresh();
      return _sameAuthSession(userId, generation) &&
          _subscriptionProvider.isPremium;
    } catch (error) {
      if (_sameAuthSession(userId, generation)) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_sameAuthSession(userId, generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _authGeneration++;
    _isLoading = false;
    _authProvider.removeListener(_handleAuthChanged);
    _entitlementSubscription?.cancel();
    _entitlementSubscription = null;
    super.dispose();
  }
}
