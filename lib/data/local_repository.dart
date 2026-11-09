import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'repository.dart';
import 'seed_data.dart';

/// Demo / offline backend. Everything lives in SharedPreferences as JSON, so
/// the app works with zero setup (and on GitHub Pages) and data survives reload.
class LocalRepository implements CampusRepository {
  LocalRepository(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _uuid = Uuid();
  static const _k = 'campuslink.store.v1';

  final _userCtrl = StreamController<Profile?>.broadcast();
  Profile? _user;

  // In-memory tables
  late List<Announcement> _announcements;
  late List<HelpRequest> _requests;
  late List<RequestUpdate> _updates;
  late List<StudyGroup> _groups;
  late List<PulsePoll> _polls;
  late List<TimetableEntry> _timetable;
  BuddyPair? _buddy;
  final List<Map<String, dynamic>> _feedback = [];

  void _load() {
    final raw = _prefs.getString(_k);
    if (raw == null) {
      _announcements = List.of(SeedData.announcements);
      _requests = [];
      _updates = [];
      _groups = List.of(SeedData.studyGroups);
      _polls = List.of(SeedData.polls);
      _timetable = List.of(SeedData.timetable);
      return;
    }
    final m = jsonDecode(raw) as Map<String, dynamic>;
    List<T> read<T>(String key, T Function(Map<String, dynamic>) f) =>
        (m[key] as List? ?? const []).map((e) => f(Map<String, dynamic>.from(e))).toList();
    _user = m['user'] == null ? null : Profile.fromMap(Map<String, dynamic>.from(m['user']));
    _announcements = read('announcements', Announcement.fromMap);
    _requests = read('requests', HelpRequest.fromMap);
    _updates = read('updates', RequestUpdate.fromMap);
    _groups = read('groups', StudyGroup.fromMap);
    _polls = read('polls', PulsePoll.fromMap);
    _timetable = read('timetable', TimetableEntry.fromMap);
    _buddy = m['buddy'] == null ? null : BuddyPair.fromMap(Map<String, dynamic>.from(m['buddy']));
    if (_announcements.isEmpty) _announcements = List.of(SeedData.announcements);
    if (_polls.isEmpty) _polls = List.of(SeedData.polls);
  }

  Future<void> _save() async {
    await _prefs.setString(
      _k,
      jsonEncode({
        'user': _user?.toMap(),
        'announcements': _announcements.map((e) => e.toMap()).toList(),
        'requests': _requests.map((e) => e.toMap()).toList(),
        'updates': _updates.map((e) => e.toMap()).toList(),
        'groups': _groups.map((e) => e.toMap()).toList(),
        'polls': _polls.map((e) => e.toMap()).toList(),
        'timetable': _timetable.map((e) => e.toMap()).toList(),
        'buddy': _buddy?.toMap(),
      }),
    );
  }

  Future<T> _tick<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 120), () => value);

  // ---- auth ----
  @override
  Stream<Profile?> get currentUser async* {
    yield _user;
    yield* _userCtrl.stream;
  }

  @override
  Profile? get currentUserSync => _user;

  void _setUser(Profile? p) {
    _user = p;
    _userCtrl.add(p);
    _save();
  }

  @override
  Future<Profile> signIn({required String email, required String password}) async {
    // Demo: any email works. A staff address switches on staff tools.
    final isStaff = email.toLowerCase().contains('staff') || email.toLowerCase().contains('admin');
    final p = Profile(
      id: 'local-${email.toLowerCase()}',
      fullName: _user?.fullName.isNotEmpty == true ? _user!.fullName : email.split('@').first,
      studentNumber: _user?.studentNumber,
      programme: _user?.programme ?? 'BDSAI',
      yearOfStudy: _user?.yearOfStudy ?? 2,
      faculty: 'FST',
      role: isStaff ? UserRole.staff : UserRole.student,
    );
    _setUser(p);
    return _tick(p);
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
    final p = Profile(
      id: 'local-${email.toLowerCase()}',
      fullName: fullName,
      studentNumber: studentNumber,
      programme: programme,
      yearOfStudy: yearOfStudy,
      faculty: 'FST',
    );
    _setUser(p);
    return _tick(p);
  }

  @override
  Future<void> signOut() async => _setUser(null);

  @override
  Future<Profile> updateProfile(Profile p) async {
    _setUser(p);
    return _tick(p);
  }

  // ---- announcements ----
  @override
  Future<List<Announcement>> announcements() {
    final list = List.of(_announcements)
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return _tick(list);
  }

  @override
  Future<void> postAnnouncement(Announcement a) async {
    _announcements.insert(0, a);
    await _save();
  }

  // ---- offices ----
  @override
  Future<List<HelpOffice>> offices() => _tick(SeedData.offices);

  // ---- requests ----
  @override
  Future<List<HelpRequest>> myRequests() {
    final uid = _user?.id;
    final list = _requests.where((r) => _user?.isStaff == true || r.studentId == uid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return _tick(list);
  }

  @override
  Future<List<RequestUpdate>> requestUpdates(String requestId) =>
      _tick(_updates.where((u) => u.requestId == requestId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

  @override
  Future<HelpRequest> createRequest(HelpRequest r) async {
    _requests.add(r);
    _updates.add(RequestUpdate(
      id: _uuid.v4(),
      requestId: r.id,
      authorId: r.studentId,
      message: 'Request submitted.',
      newStatus: 'open',
      createdAt: r.createdAt,
    ));
    // Demo magic: auto-acknowledge after a moment so students see status change.
    Future.delayed(const Duration(seconds: 4), () {
      final i = _requests.indexWhere((x) => x.id == r.id);
      if (i < 0 || _requests[i].status != RequestStatus.open) return;
      _requests[i] = _requests[i].copyWith(status: RequestStatus.inProgress, updatedAt: DateTime.now());
      _updates.add(RequestUpdate(
        id: _uuid.v4(),
        requestId: r.id,
        message: 'Your request has been received and assigned to an officer.',
        newStatus: 'in_progress',
        createdAt: DateTime.now(),
      ));
      _save();
    });
    await _save();
    return r;
  }

  @override
  Future<void> addRequestUpdate(RequestUpdate u, {RequestStatus? newStatus}) async {
    _updates.add(u);
    if (newStatus != null) {
      final i = _requests.indexWhere((x) => x.id == u.requestId);
      if (i >= 0) _requests[i] = _requests[i].copyWith(status: newStatus, updatedAt: DateTime.now());
    }
    await _save();
  }

  // ---- study ----
  @override
  Future<List<Profile>> tutors() => _tick(SeedData.tutors);

  @override
  Future<List<StudyGroup>> studyGroups() => _tick(List.of(_groups));

  @override
  Future<StudyGroup> createStudyGroup(StudyGroup g) async {
    _groups.insert(0, g);
    await _save();
    return g;
  }

  @override
  Future<void> toggleGroupMembership(String groupId, bool join) async {
    final uid = _user?.id;
    if (uid == null) return;
    final i = _groups.indexWhere((g) => g.id == groupId);
    if (i < 0) return;
    final members = List.of(_groups[i].memberIds);
    join ? (members.contains(uid) ? null : members.add(uid)) : members.remove(uid);
    _groups[i] = _groups[i].copyWith(memberIds: members);
    await _save();
  }

  // ---- pulse ----
  @override
  Future<List<PulsePoll>> polls() => _tick(List.of(_polls));

  @override
  Future<void> vote(String pollId, int optionIndex) async {
    final i = _polls.indexWhere((p) => p.id == pollId);
    if (i < 0 || _polls[i].myVote != null) return;
    final counts = List.of(_polls[i].counts);
    counts[optionIndex] += 1;
    _polls[i] = _polls[i].copyWith(counts: counts, myVote: optionIndex);
    await _save();
  }

  // ---- buddy ----
  @override
  Future<BuddyPair?> myBuddyPair() => _tick(_buddy);

  @override
  Future<BuddyPair> requestBuddy() async {
    final mentor = SeedData.tutors.firstWhere((t) => t.isBuddyMentor);
    _buddy = BuddyPair(
      id: _uuid.v4(),
      menteeId: _user?.id ?? 'anon',
      mentorId: mentor.id,
      status: 'matched',
      createdAt: DateTime.now(),
    );
    await _save();
    return _buddy!;
  }

  @override
  Future<List<Profile>> mentors() => _tick(SeedData.tutors.where((t) => t.isBuddyMentor).toList());

  // ---- engagement ----
  @override
  Future<void> submitFeedback({required String topic, required String message, String? sentiment}) async {
    _feedback.add({'topic': topic, 'message': message, 'sentiment': sentiment});
    await _tick(null);
  }

  @override
  Future<List<CampusEvent>> events() =>
      _tick(List.of(SeedData.events)..sort((a, b) => a.startsAt.compareTo(b.startsAt)));

  @override
  Future<List<Club>> clubs() => _tick(SeedData.clubs);

  // ---- timetable ----
  @override
  Future<List<TimetableEntry>> timetable() => _tick(List.of(_timetable)
    ..sort((a, b) => a.dayOfWeek != b.dayOfWeek
        ? a.dayOfWeek.compareTo(b.dayOfWeek)
        : a.startTime.compareTo(b.startTime)));

  @override
  Future<void> replaceTimetable(List<TimetableEntry> entries) async {
    _timetable = List.of(entries);
    await _save();
  }

  @override
  Future<void> addTimetableEntry(TimetableEntry e) async {
    _timetable.add(e);
    await _save();
  }

  @override
  Future<void> deleteTimetableEntry(String id) async {
    _timetable.removeWhere((e) => e.id == id);
    await _save();
  }
}
