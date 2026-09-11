import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;
  static bool _initializing = false;
  static SupabaseClient? _client;
  static Object? _lastInitializationError;

  static bool get isInitialized => _initialized && _client != null;
  static bool get isInitializing => _initializing;
  static SupabaseClient? get client => _client;
  static Object? get lastInitializationError => _lastInitializationError;

  static Future<bool> initialize(AppConfig config) async {
    if (isInitialized) return true;
    if (_initializing) return false;

    if (!config.hasSupabaseCredentials) {
      _initialized = false;
      _client = null;
      _lastInitializationError = null;
      return false;
    }

    _initializing = true;
    _lastInitializationError = null;

    try {
      final supabase = await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
      );

      _client = supabase.client;
      _initialized = true;
      return true;
    } catch (error) {
      _initialized = false;
      _client = null;
      _lastInitializationError = error;
      return false;
    } finally {
      _initializing = false;
    }
  }
}
