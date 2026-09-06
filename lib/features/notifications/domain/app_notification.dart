class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
      read: map['read'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final bool read;
  final DateTime createdAt;

  String? get actorId => payload['actor_id'] as String?;
  String? get actorName => payload['actor_name'] as String?;
  String? get actorAvatarUrl => payload['actor_avatar_url'] as String?;
  String? get postId => payload['post_id'] as String?;

  String get emoji {
    switch (type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'follow':
        return '👤';
      case 'event_joined':
        return '📅';
      case 'challenge_joined':
        return '🏆';
      case 'badge':
        return payload['badge_icon'] as String? ?? '🏅';
      case 'action_validated':
        return '✅';
      case 'report_resolved':
        return '🛠️';
      default:
        return '🔔';
    }
  }

  String get message {
    switch (type) {
      case 'like':
        return '$actorName a aimé ta publication';
      case 'comment':
        return '$actorName a commenté : "${payload['preview']}"';
      case 'follow':
        return '$actorName a commencé à te suivre';
      case 'event_joined':
        return '$actorName participe à "${payload['event_title']}"';
      case 'challenge_joined':
        return '$actorName a rejoint le défi "${payload['challenge_title']}"';
      case 'badge':
        return 'Badge débloqué : ${payload['badge_name']}';
      case 'action_validated':
        return 'Ton action a été validée';
      case 'report_resolved':
        return 'Ton signalement a été résolu';
      default:
        return 'Nouvelle notification';
    }
  }
}
