import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

class AuthRemoteDataSource {
  SupabaseClient? get _client => SupabaseService.client;

  Stream<AuthState> authStateChanges() {
    final client = _client;
    if (client == null) return const Stream<AuthState>.empty();
    return client.auth.onAuthStateChange;
  }

  User? get currentUser => _client?.auth.currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required int age,
    required String hometown,
    required String gender,
  }) async {
    final client = _requireClient();
    await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'display_name': '${firstName.trim()} ${lastName.trim()}'.trim(),
        'age': age,
        'hometown': hometown.trim(),
        'gender': gender.trim(),
      },
    );
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  Future<void> deleteAccount() async {
    final client = _requireClient();
    await client.functions.invoke('delete-account');
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Run the app with SUPABASE_URL and '
        'SUPABASE_ANON_KEY dart defines.',
      );
    }
    return client;
  }
}
