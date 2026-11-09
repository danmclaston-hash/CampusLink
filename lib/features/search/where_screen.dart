import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

class WhereScreen extends ConsumerStatefulWidget {
  const WhereScreen({super.key});

  @override
  ConsumerState<WhereScreen> createState() => _WhereScreenState();
}

class _WhereScreenState extends ConsumerState<WhereScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  static const _suggestions = [
    'pay my fees',
    'missing marks',
    'reset portal password',
    'lost my ID card',
    'I feel stressed',
    'find a hostel',
    'book a study room',
    'get an internship',
    'join a club',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(smartSearchProvider(_q));
    return Scaffold(
      appBar: AppBar(title: const Text('Where do I go?')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Type it like you would ask a friend…',
                prefixIcon: const Icon(Icons.explore_rounded),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _q = '');
                        },
                      ),
              ),
            ),
          ),
          if (_q.trim().length < 2)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SectionHeader('Try asking'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _suggestions)
                        ActionChip(
                          avatar: const Icon(Icons.bolt_rounded, size: 16, color: Brand.violet),
                          label: Text(s),
                          onPressed: () {
                            _ctrl.text = s;
                            setState(() => _q = s);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Brand.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search understands plain words. "money" finds Finance, "sad" finds Counselling, "wifi" finds the ICT desk.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: AsyncBody(
                value: results,
                builder: (hits) {
                  if (hits.isEmpty) {
                    return EmptyState(
                      icon: Icons.help_outline_rounded,
                      title: 'Not sure where that goes',
                      subtitle: 'Raise a help request and we will route it to the right office for you.',
                      action: FilledButton(onPressed: () => context.go('/requests'), child: const Text('Raise a request')),
                    );
                  }
                  final best = hits.first;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (best.kind == 'office')
                        GradientCard(
                          gradient: Brand.primaryGradient,
                          onTap: () => context.go(best.route),
                          child: Row(
                            children: [
                              const Icon(Icons.near_me_rounded, color: Colors.white, size: 30),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Go to', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                                    Text(best.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                                    Text(best.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      for (final h in hits.skip(best.kind == 'office' ? 1 : 0))
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => context.go(h.route),
                            leading: Icon(_kindIcon(h.kind), color: Brand.violet),
                            title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(h.subtitle),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _kindIcon(String k) => switch (k) {
        'office' => Icons.apartment_rounded,
        'announcement' => Icons.campaign_rounded,
        'event' => Icons.event_rounded,
        'group' => Icons.groups_rounded,
        'club' => Icons.sports_soccer_rounded,
        _ => Icons.search_rounded,
      };
}
