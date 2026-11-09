import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class BuddyScreen extends ConsumerWidget {
  const BuddyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pair = ref.watch(buddyPairProvider);
    final mentors = ref.watch(mentorsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('First-year Buddy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientCard(
            gradient: Brand.goldGradient,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.handshake_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 10),
                const Text('Nobody should figure out university alone.',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'New students get paired with a trained senior who has been where you are. Ask anything — fees, lecturers, where to eat.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.95), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AsyncBody(
            value: pair,
            onRetry: () => ref.invalidate(buddyPairProvider),
            builder: (bp) {
              if (bp == null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.isFirstYear == true
                              ? 'You are a first-year — get matched now'
                              : 'Request a buddy',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text('We match you with a mentor from your faculty who has the lightest load, so they have time for you.'),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () async {
                            await ref.read(repositoryProvider).requestBuddy();
                            ref.invalidate(buddyPairProvider);
                            if (context.mounted) showSnack(context, 'Matched! Say hi to your buddy.');
                          },
                          icon: const Icon(Icons.favorite_rounded),
                          label: const Text('Match me with a buddy'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final mentor = mentors.valueOrNull?.where((m) => m.id == bp.mentorId).firstOrNull;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Brand.amber.withValues(alpha: 0.2),
                        child: Text(mentor?.fullName.split(' ').map((w) => w[0]).take(2).join() ?? '?',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.amber, fontSize: 18)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusChip(bp.status == 'matched' ? 'Matched' : 'Waiting for a mentor', color: bp.status == 'matched' ? Brand.teal : Brand.amber),
                            const SizedBox(height: 6),
                            Text(mentor?.fullName ?? 'Finding the right mentor…', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            if (mentor != null) Text('${mentor.programme} · Year ${mentor.yearOfStudy}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (mentor != null)
                        IconButton.filledTonal(
                          onPressed: () => showSnack(context, 'Chat opens in the next release. For now, your buddy will email you.'),
                          icon: const Icon(Icons.chat_bubble_rounded),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader('Meet the mentors'),
          AsyncBody(
            value: mentors,
            builder: (list) => Column(
              children: [
                for (final m in list)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Brand.violet.withValues(alpha: 0.15),
                        child: Text(m.fullName[0], style: const TextStyle(color: Brand.violet, fontWeight: FontWeight.w800)),
                      ),
                      title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${m.programme} · Year ${m.yearOfStudy} · ${m.tutorSubjects.join(', ')}'),
                    ),
                  ),
              ].expand((w) => [w, const SizedBox(height: 8)]).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (user != null && !user.isFirstYear && !user.isBuddyMentor)
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(repositoryProvider).updateProfile(user.copyWith(isBuddyMentor: true));
                ref.invalidate(mentorsProvider);
                if (context.mounted) showSnack(context, 'Thank you! You are now a buddy mentor.');
              },
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: const Text('Volunteer as a mentor'),
            ),
        ],
      ),
    );
  }
}
