import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/local_repository.dart';
import 'data/providers.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  CampusRepository repo;
  var demo = true;

  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      repo = SupabaseRepository(Supabase.instance.client);
      demo = false;
    } catch (_) {
      // Bad keys or no network at boot: fall back so the app still opens.
      repo = LocalRepository(prefs);
    }
  } else {
    repo = LocalRepository(prefs);
  }

  runApp(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repo),
        isDemoModeProvider.overrideWithValue(demo),
      ],
      child: const CampusLinkApp(),
    ),
  );
}
