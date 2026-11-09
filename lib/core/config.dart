/// Build-time configuration.
///
/// Pass real keys with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// Without them the app runs in **demo mode** with local seeded data.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const appName = 'CampusLink';
  static const university = 'Cavendish University Uganda';
}
