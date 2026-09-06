import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(SupabaseService.client);
});

class ChallengesListState {
  const ChallengesListState({
    this.challenges = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Challenge> challenges;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  ChallengesListState copyWith({
    List<Challenge>? challenges,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ChallengesListState(
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final activeChallengesProvider =
    NotifierProvider.autoDispose<ActiveChallengesNotifier, ChallengesListState>(
  ActiveChallengesNotifier.new,
);

class ActiveChallengesNotifier extends AutoDisposeNotifier<ChallengesListState> {
  @override
  ChallengesListState build() {
    ref.watch(currentUserProvider);
    Future.microtask(refresh);
    return const ChallengesListState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      final challenges =
          await ref.read(challengeRepositoryProvider).fetchActive(currentUserId: userId);
      state = ChallengesListState(challenges: challenges, hasMore: challenges.length >= 20);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.challenges.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      final more = await ref.read(challengeRepositoryProvider).fetchActive(
            currentUserId: userId,
            after: state.challenges.last.endsAt,
          );
      state = state.copyWith(
        challenges: [...state.challenges, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final createChallengeControllerProvider =
    AsyncNotifierProvider.autoDispose<CreateChallengeController, void>(
  CreateChallengeController.new,
);

class CreateChallengeController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> publish({
    required String categoryId,
    required String title,
    required String description,
    required double targetValue,
    required String unit,
    required DateTime endsAt,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(challengeRepositoryProvider).createChallenge(
          organizerId: userId,
          categoryId: categoryId,
          title: title,
          description: description,
          targetValue: targetValue,
          unit: unit,
          endsAt: endsAt,
        ));
    if (!state.hasError) ref.invalidate(activeChallengesProvider);
    return !state.hasError;
  }
}

final challengeActionsControllerProvider =
    AsyncNotifierProvider.autoDispose<ChallengeActionsController, void>(
  ChallengeActionsController.new,
);

class ChallengeActionsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleJoin(String challengeId, {required bool isCurrentlyJoined}) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    state = const AsyncLoading();
    final repo = ref.read(challengeRepositoryProvider);
    state = await AsyncValue.guard(() {
      return isCurrentlyJoined ? repo.leave(challengeId, userId) : repo.join(challengeId, userId);
    });
    if (!state.hasError) ref.invalidate(activeChallengesProvider);
  }
}
