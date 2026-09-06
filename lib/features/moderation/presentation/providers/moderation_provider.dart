import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../actions/presentation/providers/action_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/moderation_repository.dart';
import '../../domain/content_report.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(SupabaseService.client);
});

/// `false` tant que le profil n'a pas fini de charger — évite d'afficher
/// brièvement l'entrée "Modération" avant de la retirer.
final isModeratorProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(currentProfileProvider).valueOrNull?.isModerator ?? false;
});

final pendingReportsProvider = FutureProvider.autoDispose<List<Report>>((ref) {
  return ref.watch(moderationRepositoryProvider).fetchPendingReports();
});

final moderationControllerProvider =
    AsyncNotifierProvider.autoDispose<ModerationController, void>(ModerationController.new);

class ModerationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> resolveReport({
    required String reportId,
    required String newStatus,
    required String contentAction,
  }) async {
    final moderatorId = ref.read(currentUserProvider)?.id;
    if (moderatorId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(moderationRepositoryProvider).resolveReport(
          reportId: reportId,
          moderatorId: moderatorId,
          newStatus: newStatus,
          contentAction: contentAction,
        ));
    if (!state.hasError) ref.invalidate(pendingReportsProvider);
    return !state.hasError;
  }

  Future<bool> rejectAction(String actionId) async {
    final moderatorId = ref.read(currentUserProvider)?.id;
    if (moderatorId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(actionRepositoryProvider).moderateAction(
          actionId: actionId,
          moderatorId: moderatorId,
          status: 'rejected',
        ));
    if (!state.hasError) ref.invalidate(actionsListProvider);
    return !state.hasError;
  }
}

final reportContentControllerProvider = AsyncNotifierProvider.autoDispose<
    ReportContentController, void>(ReportContentController.new);

class ReportContentController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(moderationRepositoryProvider).reportContent(
          reporterId: userId,
          targetType: targetType,
          targetId: targetId,
          reason: reason,
          description: description,
        ));
    return !state.hasError;
  }
}
