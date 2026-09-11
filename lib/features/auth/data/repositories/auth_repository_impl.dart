import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges().map(
          (state) => _mapUser(state.session?.user),
        );
  }

  @override
  AppUser? get currentUser => _mapUser(_remoteDataSource.currentUser);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signInWithEmail(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String hometown,
    required String gender,
  }) {
    return _remoteDataSource.signUpWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      age: age,
      hometown: hometown,
      gender: gender,
    );
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();

  @override
  Future<void> deleteAccount() => _remoteDataSource.deleteAccount();

  AppUser? _mapUser(User? user) {
    if (user == null) return null;

    return AppUser(
      id: user.id,
      email: user.email,
      displayName: user.userMetadata?['display_name']?.toString(),
      firstName: user.userMetadata?['first_name']?.toString(),
      lastName: user.userMetadata?['last_name']?.toString(),
      age: (user.userMetadata?['age'] as num?)?.toInt(),
      hometown: user.userMetadata?['hometown']?.toString(),
      gender: user.userMetadata?['gender']?.toString(),
      avatarUrl: user.userMetadata?['avatar_url']?.toString(),
    );
  }
}
