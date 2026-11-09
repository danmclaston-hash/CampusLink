import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

Future<void> showNewRequestSheet(BuildContext context, WidgetRef ref, {String? officeId}) async {
  final offices = await ref.read(officesProvider.future);
  if (!context.mounted) return;
  final title = TextEditingController();
  final desc = TextEditingController();
  String? office = officeId;
  var priority = 'normal';

  final created = await showModalBottomSheet<HelpRequest>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New help request', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Tell us what you need. You will get a tracking status on every update.',
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: office,
              decoration: const InputDecoration(labelText: 'Which office?'),
              items: [for (final o in offices) DropdownMenuItem(value: o.id, child: Text(o.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setS(() => office = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Short title', hintText: 'e.g. Missing marks for BDA2207')),
            const SizedBox(height: 12),
            TextField(controller: desc, maxLines: 4, decoration: const InputDecoration(labelText: 'Details')),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'normal', label: Text('Normal')),
                ButtonSegment(value: 'urgent', label: Text('Urgent')),
              ],
              selected: {priority},
              onSelectionChanged: (s) => setS(() => priority = s.first),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                final uid = ref.read(repositoryProvider).currentUserSync?.id ?? 'anon';
                final r = HelpRequest(
                  id: const Uuid().v4(),
                  studentId: uid,
                  officeId: office,
                  title: title.text.trim(),
                  description: desc.text.trim(),
                  priority: priority,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                final saved = await ref.read(repositoryProvider).createRequest(r);
                if (ctx.mounted) Navigator.pop(ctx, saved);
              },
              child: const Text('Submit request'),
            ),
          ],
        ),
      ),
    ),
  );

  if (created != null && context.mounted) {
    ref.invalidate(myRequestsProvider);
    showSnack(context, 'Request submitted. Track it under Requests.');
    context.go('/requests/${created.id}');
  }
}
