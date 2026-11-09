import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';

/// Offline schematic campus map. Buildings are drawn as tappable blocks and
/// linked to the offices inside them, so it works with no internet or map keys.
class CampusMap extends ConsumerStatefulWidget {
  const CampusMap({super.key});

  @override
  ConsumerState<CampusMap> createState() => _CampusMapState();
}

class _Building {
  const _Building(this.name, this.rect, this.gradient, {this.icon = Icons.apartment_rounded});
  final String name;
  final Rect rect; // in a 0..1 coordinate space
  final Gradient gradient;
  final IconData icon;
}

const _buildings = [
  _Building('Main Block', Rect.fromLTWH(0.06, 0.08, 0.40, 0.26), Brand.primaryGradient, icon: Icons.account_balance_rounded),
  _Building('Library Block', Rect.fromLTWH(0.54, 0.08, 0.40, 0.22), Brand.oceanGradient, icon: Icons.local_library_rounded),
  _Building('FST Block', Rect.fromLTWH(0.06, 0.44, 0.34, 0.26), Brand.forestGradient, icon: Icons.science_rounded),
  _Building("Students' Centre", Rect.fromLTWH(0.48, 0.40, 0.46, 0.22), Brand.sunsetGradient, icon: Icons.groups_rounded),
  _Building('Main Hall', Rect.fromLTWH(0.06, 0.78, 0.44, 0.16), Brand.goldGradient, icon: Icons.theater_comedy_rounded),
  _Building('Sports Pitch', Rect.fromLTWH(0.58, 0.70, 0.36, 0.24), Brand.roseGradient, icon: Icons.sports_soccer_rounded),
];

class _CampusMapState extends ConsumerState<CampusMap> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final offices = ref.watch(officesProvider).valueOrNull ?? [];
    final inside = offices.where((o) => o.building == _selected).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final map = AspectRatio(
          aspectRatio: 1.15,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: LayoutBuilder(
              builder: (_, box) => Stack(
                children: [
                  CustomPaint(size: Size(box.maxWidth, box.maxHeight), painter: _PathsPainter(Theme.of(context).colorScheme)),
                  for (final b in _buildings)
                    Positioned(
                      left: b.rect.left * box.maxWidth,
                      top: b.rect.top * box.maxHeight,
                      width: b.rect.width * box.maxWidth,
                      height: b.rect.height * box.maxHeight,
                      child: AnimatedScale(
                        scale: _selected == b.name ? 1.04 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: GradientCard(
                          gradient: b.gradient,
                          radius: 16,
                          padding: const EdgeInsets.all(10),
                          onTap: () => setState(() => _selected = _selected == b.name ? null : b.name),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(b.icon, color: Colors.white, size: 22),
                              const SizedBox(height: 4),
                              Text(b.name, textAlign: TextAlign.center, maxLines: 2,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        final panel = Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _selected == null
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const Icon(Icons.touch_app_rounded, color: Brand.violet),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Tap a building to see the offices inside and jump to them.', style: Theme.of(context).textTheme.bodyMedium)),
                    ]),
                  ),
                )
              : Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(_selected!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        subtitle: Text(inside.isEmpty ? 'No service offices here' : '${inside.length} office${inside.length == 1 ? '' : 's'}'),
                        trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _selected = null)),
                      ),
                      for (final o in inside)
                        ListTile(
                          leading: Icon(categoryIcon(o.category), color: categoryColor(o.category)),
                          title: Text(o.name),
                          subtitle: Text(o.location),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.go('/directory/${o.id}'),
                        ),
                    ],
                  ),
                ),
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: SingleChildScrollView(child: map)),
              Expanded(flex: 2, child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.only(top: 16), child: panel))),
            ],
          );
        }
        return ListView(children: [map, panel]);
      },
    );
  }
}

class _PathsPainter extends CustomPainter {
  _PathsPainter(this.scheme);
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final p = Path()
      ..moveTo(size.width * 0.50, size.height * 0.02)
      ..lineTo(size.width * 0.50, size.height * 0.98)
      ..moveTo(size.width * 0.02, size.height * 0.37)
      ..lineTo(size.width * 0.98, size.height * 0.37)
      ..moveTo(size.width * 0.02, size.height * 0.67)
      ..lineTo(size.width * 0.98, size.height * 0.67);
    canvas.drawPath(p, paint);
    final tp = TextPainter(
      text: TextSpan(text: 'Cavendish campus · schematic', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 10, size.height - tp.height - 6));
  }

  @override
  bool shouldRepaint(covariant _PathsPainter old) => old.scheme != scheme;
}
