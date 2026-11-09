import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class PulseScreen extends ConsumerWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(pollsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Pulse')),
      body: AsyncBody(
        value: data,
        onRetry: () => ref.invalidate(pollsProvider),
        builder: (polls) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GradientCard(
              gradient: Brand.roseGradient,
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Quick, anonymous check-ins. Your vote is hashed so nobody — not even staff — can see who chose what.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.95), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final p in polls) ...[_PollCard(poll: p), const SizedBox(height: 12)],
          ],
        ),
      ),
    );
  }
}

class _PollCard extends ConsumerWidget {
  const _PollCard({required this.poll});
  final PulsePoll poll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voted = poll.myVote != null;
    final colors = [Brand.indigo, Brand.violet, Brand.coral, Brand.amber, Brand.teal];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll.question, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${poll.total} responses${voted ? ' · you voted' : ''}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            for (var i = 0; i < poll.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: voted
                    ? _ResultBar(
                        label: poll.options[i],
                        fraction: poll.total == 0 ? 0 : poll.counts[i] / poll.total,
                        color: colors[i % colors.length],
                        mine: poll.myVote == i,
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await ref.read(repositoryProvider).vote(poll.id, i);
                          ref.invalidate(pollsProvider);
                        },
                        child: Text(poll.options[i]),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.label, required this.fraction, required this.color, required this.mine});
  final String label;
  final double fraction;
  final Color color;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: mine ? FontWeight.w800 : FontWeight.w500))),
          if (mine) const Icon(Icons.check_circle_rounded, size: 16, color: Brand.teal),
          const SizedBox(width: 6),
          Text('${(fraction * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 10,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }
}
