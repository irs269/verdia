import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../badges/presentation/providers/badge_provider.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../posts/data/post_repository.dart';
import '../../../posts/presentation/providers/feed_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/action_repository.dart';
import '../../domain/action_category.dart';
import '../../domain/eco_action.dart';

final actionRepositoryProvider = Provider<ActionRepository>((ref) {
  return ActionRepository(SupabaseService.client);
});

final actionCategoriesProvider = FutureProvider<List<ActionCategory>>((ref) {
  return ref.watch(actionRepositoryProvider).fetchCategories();
});

class ActionsListState {
  const ActionsListState({
    this.actions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<EcoAction> actions;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  ActionsListState copyWith({
    List<EcoAction>? actions,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ActionsListState(
      actions: actions ?? this.actions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final actionsListProvider =
    NotifierProvider.autoDispose<ActionsListNotifier, ActionsListState>(
  ActionsListNotifier.new,
);

class ActionsListNotifier extends AutoDisposeNotifier<ActionsListState> {
  @override
  ActionsListState build() {
    Future.microtask(refresh);
    return const ActionsListState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final actions = await ref.read(actionRepositoryProvider).fetchActions();
      state = ActionsListState(actions: actions, hasMore: actions.length >= 20);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.actions.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await ref
          .read(actionRepositoryProvider)
          .fetchActions(before: state.actions.last.createdAt);
      state = state.copyWith(
        actions: [...state.actions, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final userActionCountsProvider =
    FutureProvider.autoDispose.family<Map<String, int>, String>((ref, profileId) {
  return ref.watch(actionRepositoryProvider).fetchUserActionCounts(profileId);
});

final createActionControllerProvider =
    AsyncNotifierProvider.autoDispose<CreateActionController, void>(
  CreateActionController.new,
);

class CreateActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> publish({
    required String categoryId,
    required String title,
    required String description,
    double? quantity,
    String? quantityUnit,
    required int participantsCount,
    String? city,
    String? country,
    double? lat,
    double? lng,
    required List<Uint8List> mediaBytes,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(actionRepositoryProvider).createAction(
          authorId: userId,
          categoryId: categoryId,
          title: title,
          description: description,
          quantity: quantity,
          quantityUnit: quantityUnit,
          participantsCount: participantsCount,
          city: city,
          country: country,
          lat: lat,
          lng: lng,
          mediaBytes: mediaBytes,
        ));
    if (!state.hasError) {
      ref.invalidate(feedProvider(FeedType.forYou));
      ref.invalidate(feedProvider(FeedType.following));
      ref.invalidate(actionsListProvider);
      ref.invalidate(userActionCountsProvider(userId));
      ref.invalidate(currentProfileProvider);
      ref.invalidate(userBadgesProvider(userId));
      ref.invalidate(activeChallengesProvider);
    }
    return !state.hasError;
  }
}
