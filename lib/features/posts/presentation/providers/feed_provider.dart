import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/post_repository.dart';
import '../../domain/post.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(SupabaseService.client);
});

class UserPostsState {
  const UserPostsState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  UserPostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return UserPostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final userPostsProvider = NotifierProvider.autoDispose
    .family<UserPostsNotifier, UserPostsState, String>(UserPostsNotifier.new);

class UserPostsNotifier extends AutoDisposeFamilyNotifier<UserPostsState, String> {
  @override
  UserPostsState build(String arg) {
    ref.watch(currentUserProvider);
    Future.microtask(refresh);
    return const UserPostsState(isLoading: true);
  }

  String? get _userId => ref.read(currentUserProvider)?.id;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final posts = await ref.read(postRepositoryProvider).fetchUserPosts(
            authorId: arg,
            currentUserId: _userId,
          );
      state = UserPostsState(posts: posts, hasMore: posts.length >= 10);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.posts.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await ref.read(postRepositoryProvider).fetchUserPosts(
            authorId: arg,
            currentUserId: _userId,
            before: state.posts.last.createdAt,
          );
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> toggleLike(String postId) async {
    final userId = _userId;
    if (userId == null) return;
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = state.posts[index];
    final optimistic = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    _replacePost(optimistic);
    try {
      final repo = ref.read(postRepositoryProvider);
      if (post.isLikedByMe) {
        await repo.unlike(postId, userId);
      } else {
        await repo.like(postId, userId);
      }
    } catch (_) {
      _replacePost(post);
    }
  }

  Future<void> toggleSave(String postId) async {
    final userId = _userId;
    if (userId == null) return;
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = state.posts[index];
    final optimistic = post.copyWith(isSavedByMe: !post.isSavedByMe);
    _replacePost(optimistic);
    try {
      final repo = ref.read(postRepositoryProvider);
      if (post.isSavedByMe) {
        await repo.unsave(postId, userId);
      } else {
        await repo.save(postId, userId);
      }
    } catch (_) {
      _replacePost(post);
    }
  }

  void _replacePost(Post updated) {
    state = state.copyWith(
      posts: [
        for (final p in state.posts) if (p.id == updated.id) updated else p,
      ],
    );
  }
}

final savedPostsProvider =
    NotifierProvider.autoDispose<SavedPostsNotifier, UserPostsState>(SavedPostsNotifier.new);

class SavedPostsNotifier extends AutoDisposeNotifier<UserPostsState> {
  DateTime? _cursor;

  @override
  UserPostsState build() {
    ref.watch(currentUserProvider);
    Future.microtask(refresh);
    return const UserPostsState(isLoading: true);
  }

  Future<void> refresh() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    _cursor = null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await ref.read(postRepositoryProvider).fetchSavedPosts(userId: userId);
      _cursor = page.isEmpty ? null : page.last.savedAt;
      state = UserPostsState(
        posts: [for (final entry in page) entry.post],
        hasMore: page.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || state.isLoadingMore || !state.hasMore || _cursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await ref.read(postRepositoryProvider).fetchSavedPosts(
            userId: userId,
            before: _cursor,
          );
      _cursor = page.isEmpty ? _cursor : page.last.savedAt;
      state = state.copyWith(
        posts: [...state.posts, for (final entry in page) entry.post],
        isLoadingMore: false,
        hasMore: page.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> toggleSave(String postId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    // Un post "désenregistré" disparaît de cette liste (contrairement au
    // feed, où on garde juste l'état à jour sur place).
    final previous = state.posts;
    state = state.copyWith(posts: [for (final p in previous) if (p.id != postId) p]);
    try {
      await ref.read(postRepositoryProvider).unsave(postId, userId);
    } catch (_) {
      state = state.copyWith(posts: previous);
    }
  }

  Future<void> toggleLike(String postId) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = state.posts[index];
    final optimistic = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    _replacePost(optimistic);
    try {
      final repo = ref.read(postRepositoryProvider);
      if (post.isLikedByMe) {
        await repo.unlike(postId, userId);
      } else {
        await repo.like(postId, userId);
      }
    } catch (_) {
      _replacePost(post);
    }
  }

  void _replacePost(Post updated) {
    state = state.copyWith(
      posts: [
        for (final p in state.posts) if (p.id == updated.id) updated else p,
      ],
    );
  }
}

class FeedState {
  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final feedProvider =
    NotifierProvider.family<FeedNotifier, FeedState, FeedType>(FeedNotifier.new);

class FeedNotifier extends FamilyNotifier<FeedState, FeedType> {
  @override
  FeedState build(FeedType arg) {
    // Recharge le fil (et les états like/save propres au viewer) à chaque
    // changement de compte — sinon les posts mis en cache gardent les
    // isLikedByMe/isSavedByMe du compte précédent.
    ref.watch(currentUserProvider);
    Future.microtask(refresh);
    return const FeedState(isLoading: true);
  }

  String? get _userId => ref.read(currentUserProvider)?.id;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final posts = await ref.read(postRepositoryProvider).fetchFeed(
            type: arg,
            currentUserId: _userId,
          );
      state = FeedState(posts: posts, hasMore: posts.length >= 10);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.posts.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await ref.read(postRepositoryProvider).fetchFeed(
            type: arg,
            currentUserId: _userId,
            before: state.posts.last.createdAt,
          );
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> toggleLike(String postId) async {
    final userId = _userId;
    if (userId == null) return;
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = state.posts[index];
    final optimistic = post.copyWith(
      isLikedByMe: !post.isLikedByMe,
      likeCount: post.isLikedByMe ? post.likeCount - 1 : post.likeCount + 1,
    );
    _replacePost(optimistic);
    try {
      final repo = ref.read(postRepositoryProvider);
      if (post.isLikedByMe) {
        await repo.unlike(postId, userId);
      } else {
        await repo.like(postId, userId);
      }
    } catch (_) {
      _replacePost(post);
    }
  }

  Future<void> toggleSave(String postId) async {
    final userId = _userId;
    if (userId == null) return;
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = state.posts[index];
    final optimistic = post.copyWith(isSavedByMe: !post.isSavedByMe);
    _replacePost(optimistic);
    try {
      final repo = ref.read(postRepositoryProvider);
      if (post.isSavedByMe) {
        await repo.unsave(postId, userId);
      } else {
        await repo.save(postId, userId);
      }
    } catch (_) {
      _replacePost(post);
    }
  }

  /// Ajuste le compteur de commentaires en cache lorsqu'un commentaire est
  /// ajouté/supprimé depuis [CommentsScreen], sans recharger tout le fil.
  void adjustCommentCount(String postId, int delta) {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final post = state.posts[index];
    _replacePost(post.copyWith(commentCount: post.commentCount + delta));
  }

  void _replacePost(Post updated) {
    state = state.copyWith(
      posts: [
        for (final p in state.posts) if (p.id == updated.id) updated else p,
      ],
    );
  }
}
