import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../challenges/domain/challenge.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../events/domain/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../posts/domain/post.dart';
import '../../../posts/presentation/providers/feed_provider.dart';
import '../../../profile/domain/profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Le texte tel que tapé par l'utilisateur, avant debounce — voir
/// [SearchScreen]. Les providers ci-dessous ne se déclenchent que sur la
/// version "validée" (après un court silence de frappe), pour ne pas envoyer
/// une requête à chaque caractère.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

const _minQueryLength = 2;

final profileSearchResultsProvider =
    FutureProvider.autoDispose.family<List<Profile>, String>((ref, query) {
  if (query.trim().length < _minQueryLength) return Future.value(const []);
  return ref.read(profileRepositoryProvider).searchProfiles(query);
});

final postSearchResultsProvider =
    FutureProvider.autoDispose.family<List<Post>, String>((ref, query) {
  if (query.trim().length < _minQueryLength) return Future.value(const []);
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref.read(postRepositoryProvider).searchPosts(query, currentUserId: currentUserId);
});

final eventSearchResultsProvider =
    FutureProvider.autoDispose.family<List<Event>, String>((ref, query) {
  if (query.trim().length < _minQueryLength) return Future.value(const []);
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref.read(eventRepositoryProvider).searchEvents(query, currentUserId: currentUserId);
});

final challengeSearchResultsProvider =
    FutureProvider.autoDispose.family<List<Challenge>, String>((ref, query) {
  if (query.trim().length < _minQueryLength) return Future.value(const []);
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref
      .read(challengeRepositoryProvider)
      .searchChallenges(query, currentUserId: currentUserId);
});
