import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/report_repository.dart';
import '../../domain/environmental_report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(SupabaseService.client);
});

class ReportsListState {
  const ReportsListState({
    this.reports = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<EnvironmentalReport> reports;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  ReportsListState copyWith({
    List<EnvironmentalReport>? reports,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return ReportsListState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final reportsListProvider =
    NotifierProvider.autoDispose<ReportsListNotifier, ReportsListState>(
  ReportsListNotifier.new,
);

class ReportsListNotifier extends AutoDisposeNotifier<ReportsListState> {
  @override
  ReportsListState build() {
    Future.microtask(refresh);
    return const ReportsListState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reports = await ref.read(reportRepositoryProvider).fetchReports();
      state = ReportsListState(reports: reports, hasMore: reports.length >= 20);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.reports.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final more = await ref
          .read(reportRepositoryProvider)
          .fetchReports(before: state.reports.last.createdAt);
      state = state.copyWith(
        reports: [...state.reports, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

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
