import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(SupabaseService.client);
});

final activeChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref.watch(challengeRepositoryProvider).fetchActive(currentUserId: currentUserId);
});

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
