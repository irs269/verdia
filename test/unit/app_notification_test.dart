import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/notifications/domain/app_notification.dart';

Map<String, dynamic> _notificationMap({
  required String type,
  Map<String, dynamic>? payload,
  bool read = false,
}) {
  return {
    'id': 'notif-1',
    'type': type,
    'payload': payload ?? {},
    'read': read,
    'created_at': '2026-09-05T20:00:00.000Z',
  };
}

void main() {
  group('AppNotification.fromMap', () {
    test('parses the payload as a plain map', () {
      final notification = AppNotification.fromMap(_notificationMap(
        type: 'like',
        payload: {'actor_id': 'u1', 'actor_name': 'Fatima Ali', 'post_id': 'p1'},
      ));
      expect(notification.actorId, 'u1');
      expect(notification.actorName, 'Fatima Ali');
      expect(notification.postId, 'p1');
      expect(notification.read, isFalse);
    });

    test('defaults payload to an empty map when absent', () {
      final map = _notificationMap(type: 'like')..remove('payload');
      final notification = AppNotification.fromMap(map);
      expect(notification.payload, isEmpty);
      expect(notification.actorId, isNull);
    });
  });

  group('AppNotification.message', () {
    test('formats a like notification', () {
      final notification = AppNotification.fromMap(_notificationMap(
        type: 'like',
        payload: {'actor_name': 'Fatima Ali'},
      ));
      expect(notification.message, 'Fatima Ali a aimé ta publication');
    });

    test('formats a comment notification with a preview', () {
      final notification = AppNotification.fromMap(_notificationMap(
        type: 'comment',
        payload: {'actor_name': 'Fatima Ali', 'preview': 'Super initiative !'},
      ));
      expect(notification.message, 'Fatima Ali a commenté : "Super initiative !"');
    });

    test('formats a follow notification', () {
      final notification = AppNotification.fromMap(_notificationMap(
        type: 'follow',
        payload: {'actor_name': 'Fatima Ali'},
      ));
      expect(notification.message, 'Fatima Ali a commencé à te suivre');
    });

    test('formats a badge notification using the badge name', () {
      final notification = AppNotification.fromMap(_notificationMap(
        type: 'badge',
        payload: {'badge_name': 'Première action'},
      ));
      expect(notification.message, 'Badge débloqué : Première action');
    });

    test('falls back to a generic message for an unknown type', () {
      final notification = AppNotification.fromMap(_notificationMap(type: 'mystery'));
      expect(notification.message, 'Nouvelle notification');
    });
  });

  group('AppNotification.emoji', () {
    test('uses the badge icon from the payload when the type is badge', () {
      final notification = AppNotification.fromMap(_notificationMap(
        type: 'badge',
        payload: {'badge_icon': '🌳'},
      ));
      expect(notification.emoji, '🌳');
    });

    test('falls back to a generic badge emoji when none is provided', () {
      final notification = AppNotification.fromMap(_notificationMap(type: 'badge'));
      expect(notification.emoji, '🏅');
    });

    test('uses a fixed emoji for a follow notification', () {
      final notification = AppNotification.fromMap(_notificationMap(type: 'follow'));
      expect(notification.emoji, '👤');
    });
  });
}
