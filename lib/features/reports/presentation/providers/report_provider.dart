import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/report_repository.dart';
import '../../domain/environmental_report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(SupabaseService.client);
});

final reportsListProvider = FutureProvider.autoDispose<List<EnvironmentalReport>>((ref) {
  return ref.watch(reportRepositoryProvider).fetchReports();
});

final createReportControllerProvider =
    AsyncNotifierProvider.autoDispose<CreateReportController, void>(
  CreateReportController.new,
);

class CreateReportController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> publish({
    required String type,
    required String description,
    required double lat,
    required double lng,
    String? city,
    String? country,
    Uint8List? photoBytes,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(reportRepositoryProvider).createReport(
          authorId: userId,
          type: type,
          description: description,
          lat: lat,
          lng: lng,
          city: city,
          country: country,
          photoBytes: photoBytes,
        ));
    if (!state.hasError) ref.invalidate(reportsListProvider);
    return !state.hasError;
  }
}
