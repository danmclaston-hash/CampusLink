import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import '../requests/new_request_sheet.dart';

class OfficeDetailScreen extends ConsumerWidget {
  const OfficeDetailScreen({super.key, required this.officeId});
  final String officeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offices = ref.watch(officesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/directory')),
        title: const Text('Office'),
      ),
      body: AsyncBody(
        value: offices,
        builder: (list) {
          final o = list.where((x) => x.id == officeId).firstOrNull;
          if (o == null) return const EmptyState(icon: Icons.error_outline, title: 'Office not found');
          final color = categoryColor(o.category);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GradientCard(
                gradient: LinearGradient(colors: [color, Color.lerp(color, Brand.violet, 0.5)!]),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(categoryIcon(o.category), color: Colors.white, size: 36),
                    const SizedBox(height: 12),
                    Text(o.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(o.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.92), height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.place_rounded),
                      title: const Text('Location'),
                      subtitle: Text(o.location),
                      trailing: const Icon(Icons.map_outlined),
                      onTap: () => context.go('/engage'),
                    ),
                    if (o.openHours != null)
                      ListTile(leading: const Icon(Icons.schedule_rounded), title: const Text('Open hours'), subtitle: Text(o.openHours!)),
                    if (o.contactEmail != null)
                      ListTile(
                        leading: const Icon(Icons.mail_outline_rounded),
                        title: const Text('Email'),
                        subtitle: Text(o.contactEmail!),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => launchUrl(Uri.parse('mailto:${o.contactEmail}')),
                      ),
                    if (o.contactPhone != null)
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Phone'),
                        subtitle: Text(o.contactPhone!),
                        onTap: () => launchUrl(Uri.parse('tel:${o.contactPhone}')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader('This office helps with'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final k in o.keywords.take(10)) Chip(label: Text(k))],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => showNewRequestSheet(context, ref, officeId: o.id),
                icon: const Icon(Icons.add_comment_rounded),
                label: Text('Raise a request with ${o.name.split(' ').first}'),
              ),
            ],
          );
        },
      ),
    );
  }
}
