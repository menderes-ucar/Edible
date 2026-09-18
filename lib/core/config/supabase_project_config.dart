class SupabaseProjectConfig {
  SupabaseProjectConfig._();

  /// Public Supabase project URL. Safe to ship in a client application.
  static const String url = 'https://lylliolgjxmbpawkriww.supabase.co';

  /// Supabase anon / publishable key used by the client application.
  /// This is a client-side key, not the service_role key.
  /// Keep RLS policies enabled for real data protection.
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5bGxpb2xnanhtYnBhd2tyaXd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgzNDE4MDIsImV4cCI6MjEwMzkxNzgwMn0.CpLmNLfgC6M6ntbFyQmRL2LiyekE14R40_gboIBCe4Y';
}
