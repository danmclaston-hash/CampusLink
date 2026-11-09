import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'requests_screen.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  final _msg = TextEditingController();

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _send({RequestStatus? status}) async {
    final text = _msg.text.trim();
    if (text.isEmpty && status == null) return;
    await ref.read(repositoryProvider).addRequestUpdate(
          RequestUpdate(
            id: const Uuid().v4(),
            requestId: widget.requestId,
            authorId: ref.read(repositoryProvider).currentUserSync?.id,
            message: text.isEmpty ? 'Status changed to ${status!.label}.' : text,
            newStatus: status?.db,
            createdAt: DateTime.now(),
          ),
          newStatus: status,
        );
    _msg.clear();
    ref.invalidate(requestUpdatesProvider(widget.requestId));
    ref.invalidate(myRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myRequestsProvider);
    final updates = ref.watch(requestUpdatesProvider(widget.requestId));
    final offices = ref.watch(officesProvider).valueOrNull ?? [];
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/requests')),
        title: const Text('Request'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(myRequestsProvider);
              ref.invalidate(requestUpdatesProvider(widget.requestId));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: AsyncBody(
        value: requests,
        builder: (list) {
          final r = list.where((x) => x.id == widget.requestId).firstOrNull;
          if (r == null) return const EmptyState(icon: Icons.error_outline, title: 'Request not found');
          final office = offices.where((o) => o.id == r.officeId).firstOrNull;
          final canClose = r.status != RequestStatus.closed && r.status != RequestStatus.resolved;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              StatusChip(r.status.label, color: statusColor(r.status)),
                              const SizedBox(width: 8),
                              StatusChip(r.priority, color: Colors.blueGrey),
                            ]),
                            const SizedBox(height: 10),
                            Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(r.description),
                            const SizedBox(height: 10),
                            Text('${office?.name ?? 'General'} · opened ${friendlyDate(r.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProgressBar(status: r.status),
                    const SizedBox(height: 16),
                    const SectionHeader('Updates'),
                    AsyncBody(
                      value: updates,
                      builder: (ups) => Column(
                        children: [
                          for (var i = 0; i < ups.length; i++)
                            _TimelineTile(
                              update: ups[i],
                              isLast: i == ups.length - 1,
                              mine: ups[i].authorId == user?.id,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (r.status != RequestStatus.closed)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        if (user?.isStaff == true)
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final s in RequestStatus.values.where((s) => s != r.status))
                                ActionChip(
                                  label: Text('Mark ${s.label}'),
                                  avatar: Icon(Icons.flag_rounded, size: 16, color: statusColor(s)),
                                  onPressed: () => _send(status: s),
                                ),
                            ],
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msg,
                                decoration: const InputDecoration(hintText: 'Add a comment…'),
                                onSubmitted: (_) => _send(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(onPressed: () => _send(), icon: const Icon(Icons.send_rounded)),
                            if (canClose && user?.isStaff != true)
                              IconButton.outlined(
                                tooltip: 'Mark as resolved',
                                onPressed: () => _send(status: RequestStatus.resolved),
                                icon: const Icon(Icons.check_rounded),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.status});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = RequestStatus.values;
    final idx = steps.indexOf(status);
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= idx ? statusColor(steps[i]) : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(steps[i].label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: i == idx ? FontWeight.w800 : FontWeight.w500,
                        )),
              ],
            ),
          ),
          if (i < steps.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.update, required this.isLast, required this.mine});
  final RequestUpdate update;
  final bool isLast;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = update.newStatus == null
        ? Theme.of(context).colorScheme.primary
        : statusColor(RequestStatusX.parse(update.newStatus));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(mine ? 'You' : 'Support team', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(friendlyDate(update.createdAt), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 2),
                  Text(update.message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
