class SupabaseProjectConfig {
  SupabaseProjectConfig._();

  /// Public Supabase project URL. Safe to ship in a client application.
  ///
  /// The anon / publishable key is intentionally NOT stored in source code.
  /// Provide it at build time with --dart-define=SUPABASE_ANON_KEY=...
  static const String url = 'https://lylliolgjxmbpawkriww.supabase.co';

  /// Kept empty intentionally so credentials are supplied at build time.
  ///
  /// IMPORTANT:
  /// - Never put the Supabase service_role key in the mobile app.
  /// - The anon / publishable key is a client-side key and is not a server secret.
  /// - Real data security must be enforced by Supabase RLS policies.
  static const String anonKey = '';
}
