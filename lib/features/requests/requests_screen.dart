import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'new_request_sheet.dart';

Color statusColor(RequestStatus s) => switch (s) {
      RequestStatus.open => Brand.amber,
      RequestStatus.inProgress => const Color(0xFF0EA5E9),
      RequestStatus.resolved => const Color(0xFF059669),
      RequestStatus.closed => const Color(0xFF64748B),
    };

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myRequestsProvider);
    final offices = ref.watch(officesProvider).valueOrNull ?? [];
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(user?.isStaff == true ? 'All help requests' : 'My help requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNewRequestSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New request'),
      ),
      body: AsyncBody(
        value: data,
        onRetry: () => ref.invalidate(myRequestsProvider),
        builder: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.support_agent_rounded,
              title: 'No requests yet',
              subtitle: 'Raise a request with any office and follow its progress here.',
              action: FilledButton(onPressed: () => showNewRequestSheet(context, ref), child: const Text('Create one')),
            );
          }
          final openCount = list.where((r) => r.status == RequestStatus.open || r.status == RequestStatus.inProgress).length;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRequestsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              children: [
                Row(
                  children: [
                    _Stat('Active', openCount, Brand.violet),
                    const SizedBox(width: 10),
                    _Stat('Resolved', list.where((r) => r.status == RequestStatus.resolved).length, const Color(0xFF059669)),
                    const SizedBox(width: 10),
                    _Stat('Total', list.length, Brand.indigo),
                  ],
                ),
                const SizedBox(height: 16),
                for (final r in list) ...[
                  Card(
                    child: ListTile(
                      onTap: () => context.go('/requests/${r.id}'),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${offices.where((o) => o.id == r.officeId).firstOrNull?.name ?? 'General'} · updated ${friendlyDate(r.updatedAt)}',
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusChip(r.status.label, color: statusColor(r.status)),
                          if (r.priority == 'urgent')
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('URGENT', style: TextStyle(fontSize: 10, color: Brand.coral, fontWeight: FontWeight.w800)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
