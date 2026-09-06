import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../posts/domain/post.dart';
import '../../../posts/presentation/providers/feed_provider.dart';
import '../../data/hashtag_repository.dart';
import '../../domain/hashtag.dart';

final hashtagRepositoryProvider = Provider<HashtagRepository>((ref) {
  return HashtagRepository(SupabaseService.client);
});

final hashtagSearchResultsProvider =
    FutureProvider.autoDispose.family<List<Hashtag>, String>((ref, query) {
  if (query.trim().length < 2) return Future.value(const []);
  return ref.read(hashtagRepositoryProvider).searchHashtags(query);
});

final postsByHashtagProvider =
    FutureProvider.autoDispose.family<List<Post>, String>((ref, tag) {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref.read(postRepositoryProvider).fetchPostsByHashtag(tag, currentUserId: currentUserId);
});
