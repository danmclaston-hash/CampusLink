import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'repository.dart';
import 'smart_search.dart';

/// Overridden in main() with the chosen backend.
final repositoryProvider = Provider<CampusRepository>((ref) => throw UnimplementedError());

final isDemoModeProvider = Provider<bool>((ref) => true);

final currentUserProvider = StreamProvider<Profile?>(
  (ref) => ref.watch(repositoryProvider).currentUser,
);

final announcementsProvider =
    FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).announcements());

final officesProvider = FutureProvider((ref) => ref.watch(repositoryProvider).offices());

final myRequestsProvider =
    FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).myRequests());

final requestUpdatesProvider = FutureProvider.autoDispose
    .family<List<RequestUpdate>, String>((ref, id) => ref.watch(repositoryProvider).requestUpdates(id));

final tutorsProvider = FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).tutors());

final studyGroupsProvider =
    FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).studyGroups());

final pollsProvider = FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).polls());

final buddyPairProvider =
    FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).myBuddyPair());

final mentorsProvider = FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).mentors());

final eventsProvider = FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).events());

final clubsProvider = FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).clubs());

final timetableProvider =
    FutureProvider.autoDispose((ref) => ref.watch(repositoryProvider).timetable());

/// "Where do I go?" – searches offices, announcements, events, groups, clubs.
final smartSearchProvider =
    FutureProvider.autoDispose.family<List<SearchHit>, String>((ref, query) async {
  if (query.trim().length < 2) return const [];
  final repo = ref.watch(repositoryProvider);
  final results = await Future.wait([
    repo.offices(),
    repo.announcements(),
    repo.events(),
    repo.studyGroups(),
    repo.clubs(),
  ]);
  return SmartSearch.run(
    query,
    offices: results[0] as List<HelpOffice>,
    announcements: results[1] as List<Announcement>,
    events: results[2] as List<CampusEvent>,
    groups: results[3] as List<StudyGroup>,
    clubs: results[4] as List<Club>,
  );
});
