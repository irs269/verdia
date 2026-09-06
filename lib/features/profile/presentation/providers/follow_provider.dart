import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/follow_repository.dart';
import '../../domain/profile.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(SupabaseService.client);
});

final friendCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, profileId) {
  return ref.read(followRepositoryProvider).getFriendCount(profileId);
});

final isFollowingProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, targetUserId) {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  if (currentUserId == null) return Future.value(false);
  return ref.read(followRepositoryProvider).isFollowing(
        followerId: currentUserId,
        followingId: targetUserId,
      );
});

final followControllerProvider =
    AsyncNotifierProvider.autoDispose<FollowController, void>(FollowController.new);

class FollowController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> toggleFollow(String targetUserId, {required bool isCurrentlyFollowing}) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    final repo = ref.read(followRepositoryProvider);
    state = await AsyncValue.guard(() {
      return isCurrentlyFollowing
          ? repo.unfollow(followerId: userId, followingId: targetUserId)
          : repo.follow(followerId: userId, followingId: targetUserId);
    });
    if (!state.hasError) {
      ref.invalidate(isFollowingProvider(targetUserId));
      ref.invalidate(friendCountProvider(targetUserId));
      ref.invalidate(friendCountProvider(userId));
    }
    return !state.hasError;
  }
}

class FollowListState {
  const FollowListState({
    this.profiles = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Profile> profiles;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  FollowListState copyWith({
    List<Profile>? profiles,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return FollowListState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final followListProvider = NotifierProvider.autoDispose
    .family<FollowListNotifier, FollowListState, String>(FollowListNotifier.new);

class FollowListNotifier extends AutoDisposeFamilyNotifier<FollowListState, String> {
  DateTime? _cursor;

  @override
  FollowListState build(String arg) {
    Future.microtask(refresh);
    return const FollowListState(isLoading: true);
  }

  Future<List<({Profile profile, DateTime followedAt})>> _fetch({DateTime? before}) {
    return ref.read(followRepositoryProvider).fetchFriends(profileId: arg, before: before);
  }

  Future<void> refresh() async {
    _cursor = null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _fetch();
      _cursor = page.isEmpty ? null : page.last.followedAt;
      state = FollowListState(
        profiles: [for (final entry in page) entry.profile],
        hasMore: page.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || _cursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final page = await _fetch(before: _cursor);
      _cursor = page.isEmpty ? _cursor : page.last.followedAt;
      state = state.copyWith(
        profiles: [...state.profiles, for (final entry in page) entry.profile],
        isLoadingMore: false,
        hasMore: page.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}
