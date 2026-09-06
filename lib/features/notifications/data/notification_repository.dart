import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  /// Flux temps réel (Supabase Realtime) des notifications de l'utilisateur.
  Stream<List<AppNotification>> streamFor(String profileId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((rows) => rows.map(AppNotification.fromMap).toList());
  }

  Future<void> markAsRead(String id) async {
    await _client.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> markAllAsRead(String profileId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('profile_id', profileId)
        .eq('read', false);
  }
}
