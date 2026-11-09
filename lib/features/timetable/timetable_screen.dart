import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../widgets/common.dart';
import 'timetable_import.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  int _day = DateTime.now().weekday.clamp(1, 7);

  Future<void> _import() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'tsv', 'xlsx', 'xlsm', 'txt', 'pdf', 'docx', 'pptx'],
      withData: true,
    );
    final f = res?.files.firstOrNull;
    if (f == null || f.bytes == null) return;
    final user = ref.read(repositoryProvider).currentUserSync;
    try {
      final entries = TimetableImporter.parse(
        f.bytes!,
        fileName: f.name,
        courseFilter: [if (user?.programme != null) user!.programme!],
      );
      if (!mounted) return;
      if (entries.isEmpty) {
        showSnack(context, 'No classes found in that file. Check it has a Day column or day headers.');
        return;
      }
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Found ${entries.length} classes'),
          content: Text('Replace your current timetable, or add these to it?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Add')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace')),
          ],
        ),
      );
      if (replace == null) return;
      final repo = ref.read(repositoryProvider);
      if (replace) {
        await repo.replaceTimetable(entries);
      } else {
        for (final e in entries) {
          await repo.addTimetableEntry(e);
        }
      }
      ref.invalidate(timetableProvider);
      if (mounted) showSnack(context, 'Imported ${entries.length} classes from ${f.name}');
    } on UnsupportedError catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Can\'t read that file yet'),
            content: Text(e.message ?? ''),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Import failed: $e');
    }
  }

  Future<void> _addManual() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final room = TextEditingController();
    final lecturer = TextEditingController();
    var day = _day;
    var start = const TimeOfDay(hour: 8, minute: 0);
    var end = const TimeOfDay(hour: 10, minute: 0);
    String fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add a class'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: TextField(controller: code, decoration: const InputDecoration(labelText: 'Code', hintText: 'BDA2207'))),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: TextField(controller: name, decoration: const InputDecoration(labelText: 'Course name'))),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: day,
                decoration: const InputDecoration(labelText: 'Day'),
                items: [for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(dayNames[d - 1]))],
                onChanged: (v) => setS(() => day = v ?? day),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(context: ctx, initialTime: start);
                      if (t != null) setS(() => start = t);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('From ${fmt(start)}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final t = await showTimePicker(context: ctx, initialTime: end);
                      if (t != null) setS(() => end = t);
                    },
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('To ${fmt(end)}'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: room, decoration: const InputDecoration(labelText: 'Room'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: lecturer, decoration: const InputDecoration(labelText: 'Lecturer'))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok != true || code.text.trim().isEmpty) return;
    await ref.read(repositoryProvider).addTimetableEntry(TimetableEntry(
          id: const Uuid().v4(),
          courseCode: code.text.trim().toUpperCase(),
          courseName: name.text.trim().isEmpty ? null : name.text.trim(),
          dayOfWeek: day,
          startTime: fmt(start),
          endTime: fmt(end),
          room: room.text.trim().isEmpty ? null : room.text.trim(),
          lecturer: lecturer.text.trim().isEmpty ? null : lecturer.text.trim(),
        ));
    ref.invalidate(timetableProvider);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(timetableProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My timetable'),
        actions: [
          IconButton(tooltip: 'Import CSV / Excel', onPressed: _import, icon: const Icon(Icons.upload_file_rounded)),
          IconButton(
            tooltip: 'Clear all',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear timetable?'),
                  content: const Text('This removes all classes. You can import again any time.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(repositoryProvider).replaceTimetable([]);
                ref.invalidate(timetableProvider);
              }
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addManual,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add class'),
      ),
      body: AsyncBody(
        value: data,
        onRetry: () => ref.invalidate(timetableProvider),
        builder: (all) {
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No classes yet',
              subtitle: 'Import the official timetable (CSV or Excel) and we will pick out your programme\'s classes, or add them one by one.',
              action: FilledButton.icon(onPressed: _import, icon: const Icon(Icons.upload_file_rounded), label: const Text('Import file')),
            );
          }
          final todays = all.where((e) => e.dayOfWeek == _day).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    for (var d = 1; d <= 7; d++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _day = d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: _day == d ? Brand.primaryGradient : null,
                                color: _day == d ? null : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                Text(dayNames[d - 1],
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _day == d ? Colors.white : null)),
                                const SizedBox(height: 2),
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: all.any((e) => e.dayOfWeek == d)
                                        ? (_day == d ? Colors.white : Brand.violet)
                                        : Colors.transparent,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: todays.isEmpty
                    ? const EmptyState(icon: Icons.free_breakfast_rounded, title: 'Free day', subtitle: 'No classes scheduled.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: todays.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = todays[i];
                          return Dismissible(
                            key: ValueKey(e.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: Brand.coral, borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.delete_rounded, color: Colors.white),
                            ),
                            onDismissed: (_) async {
                              await ref.read(repositoryProvider).deleteTimetableEntry(e.id);
                              ref.invalidate(timetableProvider);
                            },
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(color: Brand.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                      child: Column(children: [
                                        Text(e.startTime, style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.teal)),
                                        Text(e.endTime, style: Theme.of(context).textTheme.bodySmall),
                                      ]),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(e.courseName ?? e.courseCode, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                          const SizedBox(height: 2),
                                          Text(
                                            [e.courseCode, if (e.room != null) e.room!, if (e.lecturer != null) e.lecturer!].join(' · '),
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (e.source != 'manual') const Icon(Icons.upload_file_rounded, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
