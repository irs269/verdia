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

final actionsListProvider = FutureProvider.autoDispose<List<EcoAction>>((ref) {
  return ref.watch(actionRepositoryProvider).fetchActions();
});

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
