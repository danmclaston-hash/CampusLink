import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';

class _Dest {
  const _Dest(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _dests = [
  _Dest('/home', 'Home', Icons.home_outlined, Icons.home_rounded),
  _Dest('/where', 'Where?', Icons.explore_outlined, Icons.explore_rounded),
  _Dest('/requests', 'Requests', Icons.support_agent_outlined, Icons.support_agent_rounded),
  _Dest('/timetable', 'Timetable', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
  _Dest('/profile', 'Me', Icons.person_outline_rounded, Icons.person_rounded),
];

/// Responsive scaffold: bottom bar on phones, nav rail on tablets/desktop/web.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _index {
    final i = _dests.indexWhere((d) => location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final demo = ref.watch(isDemoModeProvider);

    final body = Column(
      children: [
        if (demo)
          Material(
            color: Brand.amber.withValues(alpha: 0.16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, size: 16, color: Brand.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo mode – data is stored on this device only. Connect Supabase to go live.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => context.go(_dests[i].path),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(gradient: Brand.primaryGradient, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.hub_rounded, color: Colors.white),
                ),
              ),
              destinations: [
                for (final d in _dests)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: body),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(_dests[i].path),
        destinations: [
          for (final d in _dests)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
      ),
    );
  }
}
