import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final announcements = ref.watch(announcementsProvider);
    final timetable = ref.watch(timetableProvider);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1000 ? 4 : (width >= 600 ? 3 : 2);

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final firstName = (user?.fullName ?? '').split(' ').first;

    final today = DateTime.now().weekday;
    final todayClasses = timetable.valueOrNull?.where((e) => e.dayOfWeek == today).toList() ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(announcementsProvider);
        ref.invalidate(timetableProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Greeting + search entry
          GradientCard(
            gradient: Brand.primaryGradient,
            onTap: () => context.go('/where'),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting${firstName.isEmpty ? '' : ', $firstName'} 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('What do you need help with today?',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Brand.indigo),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Where do I go to pay fees?',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Brand.indigo, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Today
          if (todayClasses.isNotEmpty) ...[
            SectionHeader('Today · ${dayNames[today - 1]}', action: 'Timetable', onAction: () => context.go('/timetable')),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: todayClasses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = todayClasses[i];
                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(left: BorderSide(color: Brand.teal, width: 4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${c.startTime} – ${c.endTime}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.teal)),
                        const SizedBox(height: 4),
                        Text(c.courseName ?? c.courseCode,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${c.courseCode} · ${c.room ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Features
          const SectionHeader('Everything you need'),
          GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              FeatureTile(icon: Icons.campaign_rounded, title: 'Announcements', subtitle: 'Official notices, filtered for you', gradient: Brand.primaryGradient, onTap: () => context.go('/announcements')),
              FeatureTile(icon: Icons.map_rounded, title: 'Help directory', subtitle: 'Every office, what it does, where it is', gradient: Brand.oceanGradient, onTap: () => context.go('/directory')),
              FeatureTile(icon: Icons.support_agent_rounded, title: 'Help requests', subtitle: 'Raise a ticket and track its status', gradient: Brand.sunsetGradient, onTap: () => context.go('/requests')),
              FeatureTile(icon: Icons.groups_rounded, title: 'Tutors & groups', subtitle: 'Find a tutor or join a study group', gradient: Brand.forestGradient, onTap: () => context.go('/study')),
              FeatureTile(icon: Icons.monitor_heart_rounded, title: 'Campus Pulse', subtitle: 'Quick anonymous polls', gradient: Brand.roseGradient, onTap: () => context.go('/pulse')),
              FeatureTile(icon: Icons.handshake_rounded, title: 'First-year Buddy', subtitle: 'Get matched with a senior mentor', gradient: Brand.goldGradient, onTap: () => context.go('/buddy')),
              FeatureTile(icon: Icons.explore_rounded, title: 'Where do I go?', subtitle: 'Smart search across campus', gradient: Brand.primaryGradient, onTap: () => context.go('/where')),
              FeatureTile(icon: Icons.celebration_rounded, title: 'Events & clubs', subtitle: 'Feedback, events, clubs, campus map', gradient: Brand.oceanGradient, onTap: () => context.go('/engage')),
            ],
          ),
          const SizedBox(height: 20),

          // Latest announcements
          SectionHeader('Latest announcements', action: 'See all', onAction: () => context.go('/announcements')),
          AsyncBody(
            value: announcements,
            onRetry: () => ref.invalidate(announcementsProvider),
            builder: (list) => Column(
              children: [
                for (final a in list.take(3))
                  Card(
                    child: ListTile(
                      onTap: () => context.go('/announcements'),
                      leading: CircleAvatar(
                        backgroundColor: categoryColor(a.category).withValues(alpha: 0.15),
                        child: Icon(categoryIcon(a.category), color: categoryColor(a.category), size: 20),
                      ),
                      title: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(friendlyDate(a.createdAt)),
                      trailing: a.isPinned ? const Icon(Icons.push_pin_rounded, size: 18, color: Brand.coral) : null,
                    ),
                  ),
              ].expand((w) => [w, const SizedBox(height: 8)]).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
