import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/event_repository.dart';
import '../../domain/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(SupabaseService.client);
});

final upcomingEventsProvider = FutureProvider.autoDispose<List<Event>>((ref) {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  return ref.watch(eventRepositoryProvider).fetchUpcoming(currentUserId: currentUserId);
});

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
}
