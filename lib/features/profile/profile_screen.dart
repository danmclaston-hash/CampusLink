import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final demo = ref.watch(isDemoModeProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            gradient: Brand.primaryGradient,
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        [if (user.studentNumber != null) user.studentNumber!, if (user.programme != null) user.programme!, if (user.yearOfStudy != null) 'Year ${user.yearOfStudy}'].join(' · '),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, children: [
                        _Tag(user.role.name.toUpperCase()),
                        if (user.isTutor) const _Tag('TUTOR'),
                        if (user.isBuddyMentor) const _Tag('BUDDY MENTOR'),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit details'),
                  subtitle: const Text('Name, student number, programme, year'),
                  onTap: () => _edit(context, ref, user),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.school_rounded),
                  title: const Text('I can tutor other students'),
                  subtitle: Text(user.tutorSubjects.isEmpty ? 'Add subjects to appear in Find a tutor' : user.tutorSubjects.join(', ')),
                  value: user.isTutor,
                  onChanged: (v) async {
                    var subjects = user.tutorSubjects;
                    if (v && subjects.isEmpty) {
                      final c = TextEditingController();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('What can you tutor?'),
                          content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Python, Statistics, Java')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      subjects = c.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                    }
                    await ref.read(repositoryProvider).updateProfile(user.copyWith(isTutor: v, tutorSubjects: subjects));
                    ref.invalidate(tutorsProvider);
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.handshake_rounded),
                  title: const Text('I can mentor a first-year'),
                  value: user.isBuddyMentor,
                  onChanged: (v) async {
                    await ref.read(repositoryProvider).updateProfile(user.copyWith(isBuddyMentor: v));
                    ref.invalidate(mentorsProvider);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(demo ? Icons.science_rounded : Icons.cloud_done_rounded, color: demo ? Brand.amber : Brand.teal),
                  title: Text(demo ? 'Demo mode' : 'Connected to Supabase'),
                  subtitle: Text(demo
                      ? 'Data is saved on this device only. Build with SUPABASE_URL and SUPABASE_ANON_KEY to go live.'
                      : 'Your data is synced across all your devices.'),
                ),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('${AppConfig.appName} 1.0'),
                  subtitle: Text('Built for ${AppConfig.university} · IEEE / CUUCSA Innovation Challenge 2026'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(repositoryProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Profile user) async {
    final name = TextEditingController(text: user.fullName);
    final sn = TextEditingController(text: user.studentNumber ?? '');
    final prog = TextEditingController(text: user.programme ?? '');
    var year = user.yearOfStudy ?? 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Edit details'),
          content: SizedBox(
            width: 400,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 10),
              TextField(controller: sn, decoration: const InputDecoration(labelText: 'Student number')),
              const SizedBox(height: 10),
              TextField(controller: prog, decoration: const InputDecoration(labelText: 'Programme')),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: year,
                decoration: const InputDecoration(labelText: 'Year of study'),
                items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
                onChanged: (v) => setS(() => year = v ?? year),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(repositoryProvider).updateProfile(user.copyWith(
          fullName: name.text.trim(),
          studentNumber: sn.text.trim(),
          programme: prog.text.trim(),
          yearOfStudy: year,
        ));
    if (context.mounted) showSnack(context, 'Profile updated');
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}
