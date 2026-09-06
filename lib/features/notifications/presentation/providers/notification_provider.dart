import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notification_repository.dart';
import '../../domain/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(SupabaseService.client);
});

/// `null` tant que personne n'est connecté ; sinon un flux temps réel.
final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).streamFor(userId);
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.read).length;
});
