import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/event_repository.dart';
import '../../domain/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(SupabaseService.client);
});

final joinedEventsCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, profileId) {
  return ref.watch(eventRepositoryProvider).countJoinedEvents(profileId);
});

class EventsListState {
  const EventsListState({
    this.events = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Event> events;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  EventsListState copyWith({
    List<Event>? events,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return EventsListState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final upcomingEventsProvider =
    NotifierProvider.autoDispose<UpcomingEventsNotifier, EventsListState>(
  UpcomingEventsNotifier.new,
);

class UpcomingEventsNotifier extends AutoDisposeNotifier<EventsListState> {
  @override
  EventsListState build() {
    ref.watch(currentUserProvider);
    Future.microtask(refresh);
    return const EventsListState(isLoading: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      final events =
          await ref.read(eventRepositoryProvider).fetchUpcoming(currentUserId: userId);
      state = EventsListState(events: events, hasMore: events.length >= 20);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.events.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      final more = await ref.read(eventRepositoryProvider).fetchUpcoming(
            currentUserId: userId,
            after: state.events.last.startsAt,
          );
      state = state.copyWith(
        events: [...state.events, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }
}

final createEventControllerProvider =
    AsyncNotifierProvider.autoDispose<CreateEventController, void>(
  CreateEventController.new,
);

class CreateEventController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> publish({
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? city,
    String? country,
    required DateTime startsAt,
    int? targetParticipants,
    Uint8List? coverBytes,
    String? organizerOrgId,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(eventRepositoryProvider).createEvent(
          organizerId: userId,
          title: title,
          description: description,
          lat: lat,
          lng: lng,
          city: city,
          country: country,
          startsAt: startsAt,
          targetParticipants: targetParticipants,
          coverBytes: coverBytes,
          organizerOrgId: organizerOrgId,
        ));
    if (!state.hasError) ref.invalidate(upcomingEventsProvider);
    return !state.hasError;
  }

  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? city,
    String? country,
    required DateTime startsAt,
    int? targetParticipants,
    Uint8List? newCoverBytes,
    String? organizerOrgId,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(eventRepositoryProvider).updateEvent(
          eventId: eventId,
          organizerId: userId,
          title: title,
          description: description,
          lat: lat,
          lng: lng,
          city: city,
          country: country,
          startsAt: startsAt,
          targetParticipants: targetParticipants,
          newCoverBytes: newCoverBytes,
          organizerOrgId: organizerOrgId,
        ));
    if (!state.hasError) ref.invalidate(upcomingEventsProvider);
    return !state.hasError;
  }
}

final eventActionsControllerProvider =
    AsyncNotifierProvider.autoDispose<EventActionsController, void>(
  EventActionsController.new,
);

class EventActionsController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleJoin(String eventId, {required bool isCurrentlyJoined}) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    state = const AsyncLoading();
    final repo = ref.read(eventRepositoryProvider);
    state = await AsyncValue.guard(() {
      return isCurrentlyJoined ? repo.leave(eventId, userId) : repo.join(eventId, userId);
    });
    if (!state.hasError) ref.invalidate(upcomingEventsProvider);
  }

  Future<bool> cancel(String eventId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(eventRepositoryProvider).cancelEvent(eventId));
    if (!state.hasError) ref.invalidate(upcomingEventsProvider);
    return !state.hasError;
  }
}
