import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'repository.dart';

/// Live backend. Table/column names match supabase/migrations/0001_*.sql.
class SupabaseRepository implements CampusRepository {
  SupabaseRepository(this._client) {
    _client.auth.onAuthStateChange.listen((_) => _refreshProfile());
    _refreshProfile();
  }

  final SupabaseClient _client;
  final _userCtrl = StreamController<Profile?>.broadcast();
  Profile? _user;

  String get _uid => _client.auth.currentUser?.id ?? '';

  Future<void> _refreshProfile() async {
    final u = _client.auth.currentUser;
    if (u == null) {
      _user = null;
      _userCtrl.add(null);
      return;
    }
    final row = await _client.from('profiles').select().eq('id', u.id).maybeSingle();
    _user = row == null ? Profile(id: u.id, fullName: u.email ?? '') : Profile.fromMap(row);
    _userCtrl.add(_user);
  }

  // ---- auth ----
  @override
  Stream<Profile?> get currentUser async* {
    yield _user;
    yield* _userCtrl.stream;
  }

  @override
  Profile? get currentUserSync => _user;

  @override
  Future<Profile> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    await _refreshProfile();
    return _user!;
  }

  @override
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    String? studentNumber,
    String? programme,
    int? yearOfStudy,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final id = res.user?.id;
    if (id != null) {
      await _client.from('profiles').upsert({
        'id': id,
        'full_name': fullName,
        'student_number': studentNumber,
        'programme': programme,
        'year_of_study': yearOfStudy,
      });
    }
    await _refreshProfile();
    return _user ?? Profile(id: id ?? '', fullName: fullName);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<Profile> updateProfile(Profile p) async {
    await _client.from('profiles').update(p.toMap()..remove('id')).eq('id', p.id);
    await _refreshProfile();
    return _user!;
  }

  // ---- announcements ----
  @override
  Future<List<Announcement>> announcements() async {
    final rows = await _client
        .from('announcements')
        .select()
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(Announcement.fromMap).toList();
  }

  @override
  Future<void> postAnnouncement(Announcement a) =>
      _client.from('announcements').insert(a.toMap()..remove('id')..['author_id'] = _uid);

  // ---- offices ----
  @override
  Future<List<HelpOffice>> offices() async {
    final rows = await _client.from('help_offices').select().order('name');
    return rows.map(HelpOffice.fromMap).toList();
  }

  // ---- requests ----
  @override
  Future<List<HelpRequest>> myRequests() async {
    final rows = await _client.from('help_requests').select().order('updated_at', ascending: false);
    return rows.map(HelpRequest.fromMap).toList();
  }

  @override
  Future<List<RequestUpdate>> requestUpdates(String requestId) async {
    final rows = await _client
        .from('help_request_updates')
        .select()
        .eq('request_id', requestId)
        .order('created_at');
    return rows.map(RequestUpdate.fromMap).toList();
  }

  @override
  Future<HelpRequest> createRequest(HelpRequest r) async {
    final row = await _client
        .from('help_requests')
        .insert(r.toMap()..remove('id')..remove('created_at')..remove('updated_at'))
        .select()
        .single();
    final created = HelpRequest.fromMap(row);
    await _client.from('help_request_updates').insert({
      'request_id': created.id,
      'author_id': _uid,
      'message': 'Request submitted.',
      'new_status': 'open',
    });
    return created;
  }

  @override
  Future<void> addRequestUpdate(RequestUpdate u, {RequestStatus? newStatus}) async {
    await _client.from('help_request_updates').insert({
      'request_id': u.requestId,
      'author_id': _uid,
      'message': u.message,
      'new_status': newStatus?.db,
    });
    if (newStatus != null) {
      await _client.from('help_requests').update({
        'status': newStatus.db,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', u.requestId);
    }
  }

  // ---- study ----
  @override
  Future<List<Profile>> tutors() async {
    final rows = await _client.from('profiles').select().eq('is_tutor', true);
    return rows.map(Profile.fromMap).toList();
  }

  @override
  Future<List<StudyGroup>> studyGroups() async {
    final rows = await _client.from('study_groups').select('*, study_group_members(user_id)');
    return rows.map((m) {
      final members = (m['study_group_members'] as List? ?? const [])
          .map((e) => e['user_id'].toString())
          .toList();
      return StudyGroup.fromMap({...m, 'member_ids': members});
    }).toList();
  }

  @override
  Future<StudyGroup> createStudyGroup(StudyGroup g) async {
    final row = await _client
        .from('study_groups')
        .insert(g.toMap()..remove('id')..remove('member_ids')..['owner_id'] = _uid)
        .select()
        .single();
    await _client.from('study_group_members').insert({'group_id': row['id'], 'user_id': _uid});
    return StudyGroup.fromMap({...row, 'member_ids': [_uid]});
  }

  @override
  Future<void> toggleGroupMembership(String groupId, bool join) async {
    if (join) {
      await _client.from('study_group_members').upsert({'group_id': groupId, 'user_id': _uid});
    } else {
      await _client.from('study_group_members').delete().match({'group_id': groupId, 'user_id': _uid});
    }
  }

  // ---- pulse ----
  String _voterHash(String pollId) =>
      sha256.convert(utf8.encode('$_uid:$pollId')).toString();

  @override
  Future<List<PulsePoll>> polls() async {
    final polls = await _client.from('pulse_polls').select().eq('is_active', true);
    final votes = await _client.from('pulse_votes').select('poll_id, option_index, voter_hash');
    return polls.map((p) {
      final opts = List<String>.from(p['options']);
      final counts = List.filled(opts.length, 0);
      int? mine;
      final myHash = _voterHash(p['id']);
      for (final v in votes.where((v) => v['poll_id'] == p['id'])) {
        final idx = v['option_index'] as int;
        if (idx >= 0 && idx < counts.length) counts[idx]++;
        if (v['voter_hash'] == myHash) mine = idx;
      }
      return PulsePoll.fromMap({...p, 'counts': counts, 'my_vote': mine});
    }).toList();
  }

  @override
  Future<void> vote(String pollId, int optionIndex) => _client.from('pulse_votes').upsert({
        'poll_id': pollId,
        'voter_hash': _voterHash(pollId),
        'option_index': optionIndex,
      });

  // ---- buddy ----
  @override
  Future<BuddyPair?> myBuddyPair() async {
    final row = await _client
        .from('buddy_pairs')
        .select()
        .or('mentee_id.eq.$_uid,mentor_id.eq.$_uid')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : BuddyPair.fromMap(row);
  }

  @override
  Future<BuddyPair> requestBuddy() async {
    // Simple matching: pick a mentor with the fewest active mentees.
    final mentorsRows = await _client.from('profiles').select('id').eq('is_buddy_mentor', true);
    final pairs = await _client.from('buddy_pairs').select('mentor_id').eq('status', 'matched');
    String? best;
    var bestLoad = 1 << 30;
    for (final m in mentorsRows) {
      final load = pairs.where((p) => p['mentor_id'] == m['id']).length;
      if (load < bestLoad) {
        bestLoad = load;
        best = m['id'];
      }
    }
    final row = await _client
        .from('buddy_pairs')
        .insert({
          'mentee_id': _uid,
          'mentor_id': best,
          'status': best == null ? 'waiting' : 'matched',
        })
        .select()
        .single();
    return BuddyPair.fromMap(row);
  }

  @override
  Future<List<Profile>> mentors() async {
    final rows = await _client.from('profiles').select().eq('is_buddy_mentor', true);
    return rows.map(Profile.fromMap).toList();
  }

  // ---- engagement ----
  @override
  Future<void> submitFeedback({required String topic, required String message, String? sentiment}) =>
      _client.from('feedback').insert({'topic': topic, 'message': message, 'sentiment': sentiment});

  @override
  Future<List<CampusEvent>> events() async {
    final rows = await _client
        .from('events')
        .select()
        .gte('starts_at', DateTime.now().subtract(const Duration(days: 1)).toIso8601String())
        .order('starts_at');
    return rows.map(CampusEvent.fromMap).toList();
  }

  @override
  Future<List<Club>> clubs() async {
    final rows = await _client.from('clubs').select().order('name');
    return rows.map(Club.fromMap).toList();
  }

  // ---- timetable ----
  @override
  Future<List<TimetableEntry>> timetable() async {
    final rows = await _client
        .from('timetable_entries')
        .select()
        .order('day_of_week')
        .order('start_time');
    return rows.map(TimetableEntry.fromMap).toList();
  }

  @override
  Future<void> replaceTimetable(List<TimetableEntry> entries) async {
    await _client.from('timetable_entries').delete().eq('user_id', _uid);
    if (entries.isEmpty) return;
    await _client.from('timetable_entries').insert(
      entries.map((e) => e.toMap()..remove('id')..['user_id'] = _uid).toList(),
    );
  }

  @override
  Future<void> addTimetableEntry(TimetableEntry e) =>
      _client.from('timetable_entries').insert(e.toMap()..remove('id')..['user_id'] = _uid);

  @override
  Future<void> deleteTimetableEntry(String id) =>
      _client.from('timetable_entries').delete().eq('id', id);
}
