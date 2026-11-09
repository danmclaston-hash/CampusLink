// Plain data models. Each has fromMap/toMap so the same classes work for
// Supabase rows and for the local JSON store used in demo mode.

DateTime _dt(dynamic v) =>
    v == null ? DateTime.now() : (v is DateTime ? v : DateTime.parse(v.toString()));

List<String> _strList(dynamic v) =>
    v == null ? const [] : List<String>.from((v as List).map((e) => e.toString()));

enum UserRole { student, staff, admin }

class Profile {
  final String id;
  final String fullName;
  final String? studentNumber;
  final String? programme;
  final int? yearOfStudy;
  final String? faculty;
  final UserRole role;
  final bool isTutor;
  final List<String> tutorSubjects;
  final bool isBuddyMentor;

  const Profile({
    required this.id,
    required this.fullName,
    this.studentNumber,
    this.programme,
    this.yearOfStudy,
    this.faculty,
    this.role = UserRole.student,
    this.isTutor = false,
    this.tutorSubjects = const [],
    this.isBuddyMentor = false,
  });

  bool get isStaff => role != UserRole.student;
  bool get isFirstYear => yearOfStudy == 1;

  Profile copyWith({
    String? fullName,
    String? studentNumber,
    String? programme,
    int? yearOfStudy,
    String? faculty,
    UserRole? role,
    bool? isTutor,
    List<String>? tutorSubjects,
    bool? isBuddyMentor,
  }) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        studentNumber: studentNumber ?? this.studentNumber,
        programme: programme ?? this.programme,
        yearOfStudy: yearOfStudy ?? this.yearOfStudy,
        faculty: faculty ?? this.faculty,
        role: role ?? this.role,
        isTutor: isTutor ?? this.isTutor,
        tutorSubjects: tutorSubjects ?? this.tutorSubjects,
        isBuddyMentor: isBuddyMentor ?? this.isBuddyMentor,
      );

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'],
        fullName: m['full_name'] ?? '',
        studentNumber: m['student_number'],
        programme: m['programme'],
        yearOfStudy: m['year_of_study'],
        faculty: m['faculty'],
        role: UserRole.values.firstWhere((r) => r.name == (m['role'] ?? 'student'),
            orElse: () => UserRole.student),
        isTutor: m['is_tutor'] ?? false,
        tutorSubjects: _strList(m['tutor_subjects']),
        isBuddyMentor: m['is_buddy_mentor'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'student_number': studentNumber,
        'programme': programme,
        'year_of_study': yearOfStudy,
        'faculty': faculty,
        'role': role.name,
        'is_tutor': isTutor,
        'tutor_subjects': tutorSubjects,
        'is_buddy_mentor': isBuddyMentor,
      };
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final String category;
  final String audience;
  final bool isPinned;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.category = 'general',
    this.audience = 'all',
    this.isPinned = false,
    required this.createdAt,
  });

  factory Announcement.fromMap(Map<String, dynamic> m) => Announcement(
        id: m['id'],
        title: m['title'],
        body: m['body'],
        category: m['category'] ?? 'general',
        audience: m['audience'] ?? 'all',
        isPinned: m['is_pinned'] ?? false,
        createdAt: _dt(m['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'audience': audience,
        'is_pinned': isPinned,
        'created_at': createdAt.toIso8601String(),
      };
}

class HelpOffice {
  final String id;
  final String name;
  final String description;
  final String category;
  final String location;
  final String? building;
  final String? contactEmail;
  final String? contactPhone;
  final String? openHours;
  final List<String> keywords;

  const HelpOffice({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    this.building,
    this.contactEmail,
    this.contactPhone,
    this.openHours,
    this.keywords = const [],
  });

  factory HelpOffice.fromMap(Map<String, dynamic> m) => HelpOffice(
        id: m['id'],
        name: m['name'],
        description: m['description'] ?? '',
        category: m['category'] ?? 'academic',
        location: m['location'] ?? '',
        building: m['building'],
        contactEmail: m['contact_email'],
        contactPhone: m['contact_phone'],
        openHours: m['open_hours'],
        keywords: _strList(m['keywords']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'location': location,
        'building': building,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'open_hours': openHours,
        'keywords': keywords,
      };
}

enum RequestStatus { open, inProgress, resolved, closed }

extension RequestStatusX on RequestStatus {
  String get db => switch (this) {
        RequestStatus.open => 'open',
        RequestStatus.inProgress => 'in_progress',
        RequestStatus.resolved => 'resolved',
        RequestStatus.closed => 'closed',
      };
  String get label => switch (this) {
        RequestStatus.open => 'Open',
        RequestStatus.inProgress => 'In progress',
        RequestStatus.resolved => 'Resolved',
        RequestStatus.closed => 'Closed',
      };
  static RequestStatus parse(String? s) =>
      RequestStatus.values.firstWhere((v) => v.db == s, orElse: () => RequestStatus.open);
}

class HelpRequest {
  final String id;
  final String studentId;
  final String? officeId;
  final String title;
  final String description;
  final RequestStatus status;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HelpRequest({
    required this.id,
    required this.studentId,
    this.officeId,
    required this.title,
    required this.description,
    this.status = RequestStatus.open,
    this.priority = 'normal',
    required this.createdAt,
    required this.updatedAt,
  });

  HelpRequest copyWith({RequestStatus? status, DateTime? updatedAt}) => HelpRequest(
        id: id,
        studentId: studentId,
        officeId: officeId,
        title: title,
        description: description,
        status: status ?? this.status,
        priority: priority,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory HelpRequest.fromMap(Map<String, dynamic> m) => HelpRequest(
        id: m['id'],
        studentId: m['student_id'],
        officeId: m['office_id'],
        title: m['title'],
        description: m['description'],
        status: RequestStatusX.parse(m['status']),
        priority: m['priority'] ?? 'normal',
        createdAt: _dt(m['created_at']),
        updatedAt: _dt(m['updated_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'student_id': studentId,
        'office_id': officeId,
        'title': title,
        'description': description,
        'status': status.db,
        'priority': priority,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class RequestUpdate {
  final String id;
  final String requestId;
  final String? authorId;
  final String message;
  final String? newStatus;
  final DateTime createdAt;

  const RequestUpdate({
    required this.id,
    required this.requestId,
    this.authorId,
    required this.message,
    this.newStatus,
    required this.createdAt,
  });

  factory RequestUpdate.fromMap(Map<String, dynamic> m) => RequestUpdate(
        id: m['id'],
        requestId: m['request_id'],
        authorId: m['author_id'],
        message: m['message'],
        newStatus: m['new_status'],
        createdAt: _dt(m['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'request_id': requestId,
        'author_id': authorId,
        'message': message,
        'new_status': newStatus,
        'created_at': createdAt.toIso8601String(),
      };
}

class StudyGroup {
  final String id;
  final String name;
  final String courseCode;
  final String description;
  final String? meetingTime;
  final String? location;
  final String? ownerId;
  final int maxMembers;
  final List<String> memberIds;

  const StudyGroup({
    required this.id,
    required this.name,
    required this.courseCode,
    this.description = '',
    this.meetingTime,
    this.location,
    this.ownerId,
    this.maxMembers = 12,
    this.memberIds = const [],
  });

  StudyGroup copyWith({List<String>? memberIds}) => StudyGroup(
        id: id,
        name: name,
        courseCode: courseCode,
        description: description,
        meetingTime: meetingTime,
        location: location,
        ownerId: ownerId,
        maxMembers: maxMembers,
        memberIds: memberIds ?? this.memberIds,
      );

  factory StudyGroup.fromMap(Map<String, dynamic> m) => StudyGroup(
        id: m['id'],
        name: m['name'],
        courseCode: m['course_code'],
        description: m['description'] ?? '',
        meetingTime: m['meeting_time'],
        location: m['location'],
        ownerId: m['owner_id'],
        maxMembers: m['max_members'] ?? 12,
        memberIds: _strList(m['member_ids']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'course_code': courseCode,
        'description': description,
        'meeting_time': meetingTime,
        'location': location,
        'owner_id': ownerId,
        'max_members': maxMembers,
        'member_ids': memberIds,
      };
}

class PulsePoll {
  final String id;
  final String question;
  final List<String> options;
  final List<int> counts;
  final int? myVote;
  final bool isActive;

  const PulsePoll({
    required this.id,
    required this.question,
    required this.options,
    required this.counts,
    this.myVote,
    this.isActive = true,
  });

  int get total => counts.fold(0, (a, b) => a + b);

  PulsePoll copyWith({List<int>? counts, int? myVote}) => PulsePoll(
        id: id,
        question: question,
        options: options,
        counts: counts ?? this.counts,
        myVote: myVote ?? this.myVote,
        isActive: isActive,
      );

  factory PulsePoll.fromMap(Map<String, dynamic> m) {
    final opts = _strList(m['options']);
    return PulsePoll(
      id: m['id'],
      question: m['question'],
      options: opts,
      counts: m['counts'] == null
          ? List.filled(opts.length, 0)
          : List<int>.from((m['counts'] as List).map((e) => (e as num).toInt())),
      myVote: m['my_vote'],
      isActive: m['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'question': question,
        'options': options,
        'counts': counts,
        'my_vote': myVote,
        'is_active': isActive,
      };
}

class BuddyPair {
  final String id;
  final String menteeId;
  final String? mentorId;
  final String status; // waiting | matched | ended
  final DateTime createdAt;

  const BuddyPair({
    required this.id,
    required this.menteeId,
    this.mentorId,
    this.status = 'waiting',
    required this.createdAt,
  });

  factory BuddyPair.fromMap(Map<String, dynamic> m) => BuddyPair(
        id: m['id'],
        menteeId: m['mentee_id'],
        mentorId: m['mentor_id'],
        status: m['status'] ?? 'waiting',
        createdAt: _dt(m['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'mentee_id': menteeId,
        'mentor_id': mentorId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}

class CampusEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? location;
  final String? organiser;

  const CampusEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startsAt,
    this.endsAt,
    this.location,
    this.organiser,
  });

  factory CampusEvent.fromMap(Map<String, dynamic> m) => CampusEvent(
        id: m['id'],
        title: m['title'],
        description: m['description'] ?? '',
        startsAt: _dt(m['starts_at']),
        endsAt: m['ends_at'] == null ? null : _dt(m['ends_at']),
        location: m['location'],
        organiser: m['organiser'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'location': location,
        'organiser': organiser,
      };
}

class Club {
  final String id;
  final String name;
  final String description;
  final String? contact;
  final int memberCount;

  const Club({
    required this.id,
    required this.name,
    this.description = '',
    this.contact,
    this.memberCount = 0,
  });

  factory Club.fromMap(Map<String, dynamic> m) => Club(
        id: m['id'],
        name: m['name'],
        description: m['description'] ?? '',
        contact: m['contact'],
        memberCount: m['member_count'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'contact': contact,
        'member_count': memberCount,
      };
}

class TimetableEntry {
  final String id;
  final String courseCode;
  final String? courseName;
  final int dayOfWeek; // 1 = Monday … 7 = Sunday
  final String startTime; // "08:00"
  final String endTime; // "10:00"
  final String? room;
  final String? lecturer;
  final String source;

  const TimetableEntry({
    required this.id,
    required this.courseCode,
    this.courseName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    this.lecturer,
    this.source = 'manual',
  });

  factory TimetableEntry.fromMap(Map<String, dynamic> m) => TimetableEntry(
        id: m['id'],
        courseCode: m['course_code'],
        courseName: m['course_name'],
        dayOfWeek: m['day_of_week'],
        startTime: (m['start_time'] as String).substring(0, 5),
        endTime: (m['end_time'] as String).substring(0, 5),
        room: m['room'],
        lecturer: m['lecturer'],
        source: m['source'] ?? 'manual',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'course_code': courseCode,
        'course_name': courseName,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'lecturer': lecturer,
        'source': source,
      };
}

class SearchHit {
  final String title;
  final String subtitle;
  final String route;
  final double score;
  final String kind; // office | announcement | event | group | club
  const SearchHit({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.score,
    required this.kind,
  });
}
