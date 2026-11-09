import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'features/announcements/announcements_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/buddy/buddy_screen.dart';
import 'features/directory/directory_screen.dart';
import 'features/directory/office_detail_screen.dart';
import 'features/engage/engage_screen.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/pulse/pulse_screen.dart';
import 'features/requests/request_detail_screen.dart';
import 'features/requests/requests_screen.dart';
import 'features/search/where_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/study/study_screen.dart';
import 'features/timetable/timetable_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(currentUserProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      if (auth.isLoading) return null;
      final signedIn = auth.valueOrNull != null;
      final onLogin = state.matchedLocation == '/login';
      if (!signedIn && !onLogin) return '/login';
      if (signedIn && onLogin) return '/home';
      return null;
    },
    refreshListenable: _AuthNotifier(ref),
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/announcements', builder: (_, __) => const AnnouncementsScreen()),
          GoRoute(
            path: '/directory',
            builder: (_, __) => const DirectoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => OfficeDetailScreen(officeId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/requests',
            builder: (_, __) => const RequestsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => RequestDetailScreen(requestId: s.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/study', builder: (_, __) => const StudyScreen()),
          GoRoute(path: '/pulse', builder: (_, __) => const PulseScreen()),
          GoRoute(path: '/buddy', builder: (_, __) => const BuddyScreen()),
          GoRoute(path: '/where', builder: (_, __) => const WhereScreen()),
          GoRoute(path: '/engage', builder: (_, __) => const EngageScreen()),
          GoRoute(path: '/timetable', builder: (_, __) => const TimetableScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

class CampusLinkApp extends ConsumerWidget {
  const CampusLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
