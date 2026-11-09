import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';

/// A card painted with a brand gradient. Used for hero tiles and feature entry points.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.gradient,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
  });

  final Gradient gradient;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: (gradient.colors.last).withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Feature tile: icon + title + subtitle on a gradient.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradient: gradient,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(gradient: Brand.primaryGradient, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Wraps an AsyncValue into loading / error / data with a retry button.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: builder,
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, _) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load',
        subtitle: 'Check your connection and try again.\n$e',
        action: onRetry == null ? null : FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}

String friendlyDate(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24 && d.day == now.day) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return DateFormat('EEE, HH:mm').format(d);
  return DateFormat('d MMM yyyy').format(d);
}

String eventDate(DateTime d) => DateFormat('EEE d MMM · HH:mm').format(d);

const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

Color categoryColor(String c) => switch (c) {
      'finance' => Brand.amber,
      'academic' => Brand.indigo,
      'events' => Brand.violet,
      'welfare' || 'health' => Brand.coral,
      'it' => const Color(0xFF0EA5E9),
      'library' => Brand.teal,
      _ => const Color(0xFF64748B),
    };

IconData categoryIcon(String c) => switch (c) {
      'finance' => Icons.payments_rounded,
      'academic' => Icons.school_rounded,
      'events' => Icons.celebration_rounded,
      'welfare' => Icons.volunteer_activism_rounded,
      'health' => Icons.favorite_rounded,
      'it' => Icons.computer_rounded,
      'library' => Icons.local_library_rounded,
      'admin' => Icons.badge_rounded,
      _ => Icons.campaign_rounded,
    };

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}
