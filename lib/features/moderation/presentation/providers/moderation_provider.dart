import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/moderation_repository.dart';
import '../../domain/content_report.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(SupabaseService.client);
});

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
