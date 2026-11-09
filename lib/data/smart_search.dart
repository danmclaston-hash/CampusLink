import 'models.dart';

/// Lightweight on-device search: keyword overlap + fuzzy prefix matching +
/// a synonym map for the phrases students actually type.
class SmartSearch {
  static const _synonyms = <String, List<String>>{
    'money': ['fees', 'tuition', 'payment', 'finance'],
    'pay': ['fees', 'tuition', 'payment'],
    'sick': ['counselling', 'wellness', 'health'],
    'stressed': ['counselling', 'wellness', 'stress'],
    'marks': ['results', 'missing marks', 'exam'],
    'grades': ['results', 'exam'],
    'wifi': ['ict', 'internet'],
    'internet': ['ict', 'wifi'],
    'password': ['ict', 'portal'],
    'room': ['hostel', 'accommodation', 'study room'],
    'hostel': ['accommodation', 'dean of students'],
    'book': ['library', 'borrow'],
    'job': ['career', 'internship'],
    'class': ['timetable', 'lecture'],
    'lost': ['dean of students', 'id card'],
    'id': ['id card', 'registrar'],
    'letter': ['registrar', 'admission letter'],
    'register': ['registration', 'registrar'],
  };

  static List<String> _tokens(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length > 1 && !_stop.contains(t))
      .toList();

  static const _stop = {
    'where', 'do', 'i', 'go', 'to', 'for', 'the', 'a', 'an', 'my', 'is', 'how', 'can', 'who', 'what',
    'when', 'about', 'with', 'get', 'need', 'help', 'me', 'and', 'of', 'in', 'on', 'at', 'want', 'have',
  };

  static double _score(List<String> q, String haystack, {double weight = 1}) {
    final h = haystack.toLowerCase();
    var s = 0.0;
    for (final t in q) {
      if (h.contains(' $t ') || h.startsWith('$t ') || h.endsWith(' $t') || h == t) {
        s += 2 * weight;
      } else if (h.contains(t)) {
        s += 1.2 * weight;
      } else if (t.length > 3 && h.contains(t.substring(0, t.length - 1))) {
        s += 0.6 * weight; // crude stemming: "payments" ~ "payment"
      }
      for (final syn in _synonyms[t] ?? const []) {
        if (h.contains(syn)) s += 1.5 * weight;
      }
    }
    return s;
  }

  static List<SearchHit> run(
    String query, {
    required List<HelpOffice> offices,
    required List<Announcement> announcements,
    required List<CampusEvent> events,
    required List<StudyGroup> groups,
    required List<Club> clubs,
  }) {
    final q = _tokens(query);
    if (q.isEmpty) return const [];
    final hits = <SearchHit>[];

    for (final o in offices) {
      final s = _score(q, '${o.name} ${o.description} ${o.keywords.join(' ')} ${o.category}', weight: 1.3);
      if (s > 0) {
        hits.add(SearchHit(
          title: o.name,
          subtitle: '${o.location} · ${o.openHours ?? ''}',
          route: '/directory/${o.id}',
          score: s,
          kind: 'office',
        ));
      }
    }
    for (final a in announcements) {
      final s = _score(q, '${a.title} ${a.body} ${a.category}');
      if (s > 0) {
        hits.add(SearchHit(title: a.title, subtitle: 'Announcement', route: '/announcements', score: s, kind: 'announcement'));
      }
    }
    for (final e in events) {
      final s = _score(q, '${e.title} ${e.description} ${e.organiser ?? ''} ${e.location ?? ''}');
      if (s > 0) {
        hits.add(SearchHit(title: e.title, subtitle: 'Event · ${e.location ?? ''}', route: '/engage', score: s, kind: 'event'));
      }
    }
    for (final g in groups) {
      final s = _score(q, '${g.name} ${g.courseCode} ${g.description}');
      if (s > 0) {
        hits.add(SearchHit(title: g.name, subtitle: 'Study group · ${g.courseCode}', route: '/study', score: s, kind: 'group'));
      }
    }
    for (final c in clubs) {
      final s = _score(q, '${c.name} ${c.description}');
      if (s > 0) {
        hits.add(SearchHit(title: c.name, subtitle: 'Club · ${c.memberCount} members', route: '/engage', score: s, kind: 'club'));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(12).toList();
  }
}
