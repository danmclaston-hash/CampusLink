import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';

import '../../data/models.dart';

/// Parses a CSV or Excel timetable into [TimetableEntry]s.
///
/// Accepts two layouts:
///  1. **Row per class**: columns like course_code, course_name, day, start, end, room, lecturer
///     (header names are matched loosely – "Course", "Unit", "Day", "Time", "Venue" all work).
///  2. **Grid**: first column = time slots ("08:00-10:00"), header row = days, cells = course text.
///
/// If [courseFilter] is given (e.g. the student's programme code), rows whose
/// course text does not contain any of those codes are dropped.
class TimetableImporter {
  static const _uuid = Uuid();

  static List<TimetableEntry> parse(
    Uint8List bytes, {
    required String fileName,
    List<String> courseFilter = const [],
  }) {
    final lower = fileName.toLowerCase();
    final List<List<String>> rows;
    if (lower.endsWith('.csv') || lower.endsWith('.tsv') || lower.endsWith('.txt')) {
      final text = String.fromCharCodes(bytes);
      final sep = lower.endsWith('.tsv') || text.split('\n').first.contains('\t') ? '\t' : ',';
      rows = const CsvToListConverter(shouldParseNumbers: false)
          .convert(text.replaceAll('\r\n', '\n'), fieldDelimiter: sep, eol: '\n')
          .map((r) => r.map((c) => c.toString().trim()).toList())
          .toList();
    } else if (lower.endsWith('.xlsx') || lower.endsWith('.xlsm')) {
      final book = Excel.decodeBytes(bytes);
      rows = [];
      for (final sheet in book.tables.values) {
        for (final r in sheet.rows) {
          rows.add(r.map((c) => (c?.value?.toString() ?? '').trim()).toList());
        }
      }
    } else {
      throw UnsupportedError(
        'Only .csv, .tsv and .xlsx files can be read on-device. '
        'Export your PDF/Word timetable to Excel or CSV first, or add classes manually.',
      );
    }

    final clean = rows.where((r) => r.any((c) => c.isNotEmpty)).toList();
    if (clean.isEmpty) return const [];

    final header = clean.first.map((h) => h.toLowerCase()).toList();
    final isRowLayout = header.any((h) => h.contains('course') || h.contains('unit') || h.contains('code')) &&
        header.any((h) => h.contains('day'));

    final entries = isRowLayout ? _parseRows(clean) : _parseGrid(clean);
    if (courseFilter.isEmpty) return entries;
    final f = courseFilter.map((c) => c.toLowerCase()).toList();
    final filtered = entries
        .where((e) => f.any((c) =>
            e.courseCode.toLowerCase().contains(c) || (e.courseName ?? '').toLowerCase().contains(c)))
        .toList();
    return filtered.isEmpty ? entries : filtered; // never return nothing when the filter is too strict
  }

  // ---- layout 1 ----
  static List<TimetableEntry> _parseRows(List<List<String>> rows) {
    final h = rows.first.map((x) => x.toLowerCase()).toList();
    int col(List<String> keys) => h.indexWhere((x) => keys.any((k) => x.contains(k)));
    final cCode = col(['code', 'course', 'unit']);
    final cName = col(['name', 'title', 'description']);
    final cDay = col(['day']);
    final cStart = col(['start', 'from', 'time']);
    final cEnd = col(['end', 'to']);
    final cRoom = col(['room', 'venue', 'hall', 'lab', 'location']);
    final cLect = col(['lecturer', 'teacher', 'instructor', 'tutor']);

    String at(List<String> r, int i) => i >= 0 && i < r.length ? r[i] : '';
    final out = <TimetableEntry>[];
    for (final r in rows.skip(1)) {
      final day = parseDay(at(r, cDay));
      if (day == null) continue;
      var start = normalizeTime(at(r, cStart));
      var end = normalizeTime(at(r, cEnd));
      // "08:00-10:00" in a single "time" column
      if (end == null && at(r, cStart).contains('-')) {
        final parts = at(r, cStart).split(RegExp(r'\s*[-–]\s*'));
        start = normalizeTime(parts[0]);
        end = parts.length > 1 ? normalizeTime(parts[1]) : null;
      }
      if (start == null) continue;
      final code = at(r, cCode);
      if (code.isEmpty) continue;
      out.add(TimetableEntry(
        id: _uuid.v4(),
        courseCode: code,
        courseName: cName >= 0 && cName != cCode ? at(r, cName) : null,
        dayOfWeek: day,
        startTime: start,
        endTime: end ?? _plusHours(start, 2),
        room: at(r, cRoom).isEmpty ? null : at(r, cRoom),
        lecturer: at(r, cLect).isEmpty ? null : at(r, cLect),
        source: 'import',
      ));
    }
    return out;
  }

  // ---- layout 2 ----
  static List<TimetableEntry> _parseGrid(List<List<String>> rows) {
    final header = rows.first;
    final dayCols = <int, int>{};
    for (var i = 1; i < header.length; i++) {
      final d = parseDay(header[i]);
      if (d != null) dayCols[i] = d;
    }
    if (dayCols.isEmpty) return const [];
    final out = <TimetableEntry>[];
    for (final r in rows.skip(1)) {
      if (r.isEmpty) continue;
      final slot = r[0].split(RegExp(r'\s*[-–]\s*'));
      final start = normalizeTime(slot[0]);
      if (start == null) continue;
      final end = slot.length > 1 ? normalizeTime(slot[1]) : null;
      dayCols.forEach((ci, day) {
        if (ci >= r.length || r[ci].isEmpty) return;
        final text = r[ci];
        final codeMatch = RegExp(r'[A-Z]{2,5}\s?\d{3,4}').firstMatch(text);
        final roomMatch = RegExp(r'(?:room|lab|lt|hall)\s*\w+', caseSensitive: false).firstMatch(text);
        out.add(TimetableEntry(
          id: _uuid.v4(),
          courseCode: codeMatch?.group(0)?.replaceAll(' ', '') ?? text.split(RegExp(r'[\n,;]')).first.trim(),
          courseName: codeMatch == null ? null : text.replaceFirst(codeMatch.group(0)!, '').replaceAll(RegExp(r'[\n;,]+'), ' ').trim(),
          dayOfWeek: day,
          startTime: start,
          endTime: end ?? _plusHours(start, 2),
          room: roomMatch?.group(0),
          source: 'import',
        ));
      });
    }
    return out;
  }

  // ---- helpers ----
  static int? parseDay(String s) {
    final t = s.toLowerCase().trim();
    if (t.isEmpty) return null;
    const map = {
      'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4, 'fri': 5, 'sat': 6, 'sun': 7,
    };
    for (final e in map.entries) {
      if (t.startsWith(e.key)) return e.value;
    }
    final n = int.tryParse(t);
    return n != null && n >= 1 && n <= 7 ? n : null;
  }

  /// "8", "8am", "08:00", "8.30", "14h00", "2:30 pm" → "HH:mm"
  static String? normalizeTime(String s) {
    final t = s.toLowerCase().replaceAll(RegExp(r'\s'), '').replaceAll('h', ':').replaceAll('.', ':');
    final m = RegExp(r'^(\d{1,2})(?::(\d{2}))?(am|pm)?$').firstMatch(t);
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final mm = m.group(2) ?? '00';
    final ap = m.group(3);
    if (ap == 'pm' && h < 12) h += 12;
    if (ap == 'am' && h == 12) h = 0;
    if (h > 23) return null;
    return '${h.toString().padLeft(2, '0')}:$mm';
  }

  static String _plusHours(String hhmm, int hours) {
    final h = (int.parse(hhmm.substring(0, 2)) + hours).clamp(0, 23);
    return '${h.toString().padLeft(2, '0')}${hhmm.substring(2)}';
  }
}
