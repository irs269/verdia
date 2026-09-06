import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/post_repository.dart';
import '../../domain/comment.dart';
import 'feed_provider.dart';

class CommentsState {
  const CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Comment> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  CommentsState copyWith({
    List<Comment>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Signal Realtime "un commentaire a été ajouté/supprimé" pour un post donné
/// (migration 0014) — voir [PostRepository.streamCommentsChanged] pour la
/// raison de ne pas en tirer directement les commentaires.
final commentsChangedProvider =
    StreamProvider.autoDispose.family<void, String>((ref, postId) {
  return ref.read(postRepositoryProvider).streamCommentsChanged(postId);
});

final commentsProvider = NotifierProvider.autoDispose
    .family<CommentsNotifier, CommentsState, String>(CommentsNotifier.new);

class CommentsNotifier extends AutoDisposeFamilyNotifier<CommentsState, String> {
  @override
  CommentsState build(String arg) {
    Future.microtask(refresh);
    ref.listen(commentsChangedProvider(arg), (_, next) {
      if (next.hasValue) refresh();
    });
    return const CommentsState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final comments = await ref.read(postRepositoryProvider).fetchComments(arg);
      state = CommentsState(comments: comments, hasMore: comments.length >= 20);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.comments.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await ref.read(postRepositoryProvider).fetchComments(
            arg,
            after: state.comments.last.createdAt,
          );
      state = state.copyWith(
        comments: [...state.comments, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final commentControllerProvider =
    AsyncNotifierProvider.autoDispose<CommentController, void>(CommentController.new);

class CommentController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> addComment(String postId, String content) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(postRepositoryProvider)
        .addComment(postId: postId, authorId: userId, content: content));
    if (!state.hasError) {
      await ref.read(commentsProvider(postId).notifier).refresh();
      _adjustFeedCommentCounts(postId, 1);
    }
    return !state.hasError;
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(postRepositoryProvider).deleteComment(commentId),
    );
    if (!state.hasError) {
      await ref.read(commentsProvider(postId).notifier).refresh();
      _adjustFeedCommentCounts(postId, -1);
    }
    return !state.hasError;
  }

  void _adjustFeedCommentCounts(String postId, int delta) {
    for (final type in FeedType.values) {
      ref.read(feedProvider(type).notifier).adjustCommentCount(postId, delta);
    }
  }
}
