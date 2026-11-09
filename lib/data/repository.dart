import 'models.dart';

/// Everything the UI needs from a backend. Two implementations:
/// [LocalRepository] (demo / offline) and [SupabaseRepository] (live).
abstract class CampusRepository {
  // ---- auth ----
  Stream<Profile?> get currentUser;
  Profile? get currentUserSync;
  Future<Profile> signIn({required String email, required String password});
  Future<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    String? studentNumber,
    String? programme,
    int? yearOfStudy,
  });
  Future<void> signOut();
  Future<Profile> updateProfile(Profile p);

  // ---- announcements ----
  Future<List<Announcement>> announcements();
  Future<void> postAnnouncement(Announcement a);

  // ---- help directory ----
  Future<List<HelpOffice>> offices();

  // ---- help requests ----
  Future<List<HelpRequest>> myRequests();
  Future<List<RequestUpdate>> requestUpdates(String requestId);
  Future<HelpRequest> createRequest(HelpRequest r);
  Future<void> addRequestUpdate(RequestUpdate u, {RequestStatus? newStatus});

  // ---- study ----
  Future<List<Profile>> tutors();
  Future<List<StudyGroup>> studyGroups();
  Future<StudyGroup> createStudyGroup(StudyGroup g);
  Future<void> toggleGroupMembership(String groupId, bool join);

  // ---- pulse ----
  Future<List<PulsePoll>> polls();
  Future<void> vote(String pollId, int optionIndex);

  // ---- buddy ----
  Future<BuddyPair?> myBuddyPair();
  Future<BuddyPair> requestBuddy();
  Future<List<Profile>> mentors();

  // ---- engagement ----
  Future<void> submitFeedback({required String topic, required String message, String? sentiment});
  Future<List<CampusEvent>> events();
  Future<List<Club>> clubs();

  // ---- timetable ----
  Future<List<TimetableEntry>> timetable();
  Future<void> replaceTimetable(List<TimetableEntry> entries);
  Future<void> addTimetableEntry(TimetableEntry e);
  Future<void> deleteTimetableEntry(String id);
}
