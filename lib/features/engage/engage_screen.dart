import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'campus_map.dart';

class EngageScreen extends ConsumerStatefulWidget {
  const EngageScreen({super.key});

  @override
  ConsumerState<EngageScreen> createState() => _EngageScreenState();
}

class _EngageScreenState extends ConsumerState<EngageScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus life'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [Tab(text: 'Events'), Tab(text: 'Clubs'), Tab(text: 'Campus map'), Tab(text: 'Feedback')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_EventsTab(), _ClubsTab(), CampusMap(), _FeedbackTab()],
      ),
    );
  }
}

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(eventsProvider);
    return AsyncBody(
      value: data,
      onRetry: () => ref.invalidate(eventsProvider),
      builder: (list) => list.isEmpty
          ? const EmptyState(icon: Icons.event_busy_rounded, title: 'No upcoming events')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final e = list[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(gradient: Brand.sunsetGradient, borderRadius: BorderRadius.circular(12)),
                          child: Column(children: [
                            Text('${e.startsAt.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                            Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][e.startsAt.month - 1],
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 6),
                              Text('${eventDate(e.startsAt)} · ${e.location ?? ''}${e.organiser == null ? '' : ' · ${e.organiser}'}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ClubsTab extends ConsumerWidget {
  const _ClubsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clubsProvider);
    final gradients = [Brand.primaryGradient, Brand.oceanGradient, Brand.forestGradient, Brand.goldGradient, Brand.roseGradient];
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900 ? 3 : (width >= 560 ? 2 : 1);
    return AsyncBody(
      value: data,
      onRetry: () => ref.invalidate(clubsProvider),
      builder: (list) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 140),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final c = list[i];
          return GradientCard(
            gradient: gradients[i % gradients.length],
            onTap: () => showSnack(context, c.contact == null ? 'Ask the Dean of Students office to join ${c.name}.' : 'Email ${c.contact} to join.'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Expanded(child: Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.9)))),
                Row(children: [
                  const Icon(Icons.people_alt_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('${c.memberCount} members', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const Spacer(),
                  const Text('Join →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeedbackTab extends ConsumerStatefulWidget {
  const _FeedbackTab();

  @override
  ConsumerState<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends ConsumerState<_FeedbackTab> {
  final _msg = TextEditingController();
  String _topic = 'Teaching';
  String _sentiment = 'neutral';
  bool _sent = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return EmptyState(
        icon: Icons.check_rounded,
        title: 'Thank you',
        subtitle: 'Your feedback was sent anonymously to the Dean of Students.',
        action: OutlinedButton(onPressed: () => setState(() => _sent = false), child: const Text('Send another')),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const Icon(Icons.lock_rounded, color: Brand.teal),
              const SizedBox(width: 12),
              Expanded(child: Text('100% anonymous. We store the message only — never your name or account.', style: Theme.of(context).textTheme.bodyMedium)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _topic,
          decoration: const InputDecoration(labelText: 'Topic'),
          items: [for (final t in ['Teaching', 'Facilities', 'Fees & finance', 'Safety', 'Food', 'Other']) DropdownMenuItem(value: t, child: Text(t))],
          onChanged: (v) => setState(() => _topic = v ?? _topic),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'positive', label: Text('Positive'), icon: Icon(Icons.sentiment_satisfied_rounded)),
            ButtonSegment(value: 'neutral', label: Text('Neutral'), icon: Icon(Icons.sentiment_neutral_rounded)),
            ButtonSegment(value: 'negative', label: Text('Concern'), icon: Icon(Icons.sentiment_dissatisfied_rounded)),
          ],
          selected: {_sentiment},
          onSelectionChanged: (s) => setState(() => _sentiment = s.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: _msg, maxLines: 6, decoration: const InputDecoration(labelText: 'Your feedback', hintText: 'What should change? What is working?')),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            if (_msg.text.trim().isEmpty) return;
            await ref.read(repositoryProvider).submitFeedback(topic: _topic, message: _msg.text.trim(), sentiment: _sentiment);
            _msg.clear();
            setState(() => _sent = true);
          },
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send anonymously'),
        ),
      ],
    );
  }
}
