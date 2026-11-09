import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../widgets/common.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  String _q = '';
  String _cat = 'all';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(officesProvider);
    const cats = ['all', 'academic', 'finance', 'admin', 'it', 'library', 'welfare', 'health'];
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1000 ? 3 : (width >= 640 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Help directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(hintText: 'Search offices or services…', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(cats[i] == 'it' ? 'IT' : cats[i][0].toUpperCase() + cats[i].substring(1)),
                selected: _cat == cats[i],
                onSelected: (_) => setState(() => _cat = cats[i]),
              ),
            ),
          ),
          Expanded(
            child: AsyncBody(
              value: data,
              onRetry: () => ref.invalidate(officesProvider),
              builder: (list) {
                final q = _q.toLowerCase();
                final shown = list.where((o) {
                  final matchesCat = _cat == 'all' || o.category == _cat;
                  final matchesQ = q.isEmpty ||
                      o.name.toLowerCase().contains(q) ||
                      o.description.toLowerCase().contains(q) ||
                      o.keywords.any((k) => k.contains(q));
                  return matchesCat && matchesQ;
                }).toList();
                if (shown.isEmpty) return const EmptyState(icon: Icons.search_off_rounded, title: 'No office matches');
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 150,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final o = shown[i];
                    final color = categoryColor(o.category);
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/directory/${o.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: color.withValues(alpha: 0.15),
                                    child: Icon(categoryIcon(o.category), color: color, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(o.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(o.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(o.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
