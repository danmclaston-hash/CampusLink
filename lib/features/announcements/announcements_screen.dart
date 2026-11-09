import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _filter = 'all';

  /// "For me" keeps notices that target everyone or match the user's year/faculty/programme.
  bool _forMe(Announcement a, Profile? u) {
    if (a.audience == 'all' || u == null) return true;
    final parts = a.audience.split(':');
    if (parts.length != 2) return true;
    return switch (parts[0]) {
      'year' => u.yearOfStudy?.toString() == parts[1],
      'faculty' => u.faculty == parts[1],
      'programme' => u.programme == parts[1],
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final data = ref.watch(announcementsProvider);
    final categories = ['all', 'for me', 'academic', 'finance', 'events', 'welfare', 'general'];

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: user?.isStaff == true
          ? FloatingActionButton.extended(
              onPressed: () => _compose(context),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Post'),
            )
          : null,
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = categories[i];
                final sel = c == _filter;
                return ChoiceChip(
                  label: Text(c[0].toUpperCase() + c.substring(1)),
                  selected: sel,
                  onSelected: (_) => setState(() => _filter = c),
                );
              },
            ),
          ),
          Expanded(
            child: AsyncBody(
              value: data,
              onRetry: () => ref.invalidate(announcementsProvider),
              builder: (list) {
                final shown = list.where((a) {
                  if (_filter == 'all') return true;
                  if (_filter == 'for me') return _forMe(a, user);
                  return a.category == _filter;
                }).toList();
                if (shown.isEmpty) {
                  return const EmptyState(icon: Icons.campaign_rounded, title: 'Nothing here yet');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(announcementsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _AnnouncementCard(shown[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _compose(BuildContext context) async {
    final title = TextEditingController();
    final body = TextEditingController();
    var category = 'general';
    var audience = 'all';
    var pinned = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New announcement'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 10),
                TextField(controller: body, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [for (final c in ['general', 'academic', 'finance', 'events', 'welfare']) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => setS(() => category = v ?? 'general'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: audience,
                      decoration: const InputDecoration(labelText: 'Audience'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Everyone')),
                        DropdownMenuItem(value: 'year:1', child: Text('Year 1')),
                        DropdownMenuItem(value: 'faculty:FST', child: Text('FST')),
                      ],
                      onChanged: (v) => setS(() => audience = v ?? 'all'),
                    ),
                  ),
                ]),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Pin to top'),
                  value: pinned,
                  onChanged: (v) => setS(() => pinned = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
          ],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty || !mounted) return;
    await ref.read(repositoryProvider).postAnnouncement(Announcement(
          id: const Uuid().v4(),
          title: title.text.trim(),
          body: body.text.trim(),
          category: category,
          audience: audience,
          isPinned: pinned,
          createdAt: DateTime.now(),
        ));
    ref.invalidate(announcementsProvider);
    if (!mounted) return;
    showSnack(this.context, 'Announcement posted');
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard(this.a);
  final Announcement a;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(a.category);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(a.category, color: color),
                if (a.audience != 'all') ...[
                  const SizedBox(width: 6),
                  StatusChip(a.audience.replaceAll(':', ' '), color: Brand.violet),
                ],
                const Spacer(),
                if (a.isPinned) const Icon(Icons.push_pin_rounded, size: 16, color: Brand.coral),
                const SizedBox(width: 6),
                Text(friendlyDate(a.createdAt), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            Text(a.body, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
