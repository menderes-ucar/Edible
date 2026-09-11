import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository repository,
  }) : _repository = repository {
    _user = repository.currentUser;
    _subscription = repository.authStateChanges().listen(
      (user) {
        if (_disposed) return;

        _user = user;
        _errorMessage = null;
        _operationGeneration++;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_disposed) return;

        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  final AuthRepository _repository;

  StreamSubscription<AppUser?>? _subscription;
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;
  int _operationGeneration = 0;
  bool _disposed = false;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _user == null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_disposed) return false;

    return _run(
      () => _repository.signInWithEmail(
        email: email.trim(),
        password: password,
      ),
      syncCurrentUser: true,
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String hometown,
    required String gender,
  }) async {
    if (_disposed) return false;

    return _run(
      () => _repository.signUpWithEmail(
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        age: age,
        hometown: hometown.trim(),
        gender: gender.trim(),
      ),
      syncCurrentUser: true,
    );
  }

  Future<bool> deleteAccount() async {
    if (_disposed || _isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await _repository.deleteAccount();
      if (_disposed) return true;
      _user = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (_disposed) return false;
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signOut() async {
    if (_disposed || _isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      // Do not route sign-out through _run(). Supabase emits the auth-state
      // event while signOut() is completing, which increments the operation
      // generation and can make an otherwise successful logout look like a
      // failed operation to the caller.
      await _repository.signOut();

      if (_disposed) return true;

      _user = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (_disposed) return false;

      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> _run(
    Future<void> Function() action, {
    bool syncCurrentUser = false,
  }) async {
    if (_disposed || _isLoading) return false;

    final generation = ++_operationGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      await action();

      if (!_isCurrent(generation)) return false;

      if (syncCurrentUser) {
        _user = _repository.currentUser;
      }

      return true;
    } catch (error) {
      if (_isCurrent(generation)) {
        _errorMessage = error.toString();
      }
      return false;
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void clearError() {
    if (_disposed || _errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _operationGeneration;
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _operationGeneration++;
    _isLoading = false;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
