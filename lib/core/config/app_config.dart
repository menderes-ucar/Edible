import 'supabase_project_config.dart';

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;

  factory AppConfig.fromEnvironment() {
    const environmentUrl = String.fromEnvironment('SUPABASE_URL');
    const environmentAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final url = environmentUrl.trim().isNotEmpty
        ? environmentUrl.trim()
        : SupabaseProjectConfig.url.trim();

    final key = environmentAnonKey.trim().isNotEmpty
        ? environmentAnonKey.trim()
        : SupabaseProjectConfig.anonKey.trim();

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: key,
    );
  }

  bool get hasSupabaseCredentials =>
      _hasValidSupabaseUrl && _hasUsableAnonKey;

  bool get _hasValidSupabaseUrl {
    final uri = Uri.tryParse(supabaseUrl.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty;
  }

  bool get _hasUsableAnonKey {
    final key = supabaseAnonKey.trim();
    return key.isNotEmpty &&
        key != 'PASTE_SUPABASE_ANON_KEY_HERE' &&
        key != 'YOUR_SUPABASE_ANON_KEY';
  }
}
