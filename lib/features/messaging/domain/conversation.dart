/// Une conversation telle que renvoyée par la fonction RPC
/// `list_my_conversations` (migration 0027) : agrège en une seule ligne
/// l'identité de l'interlocuteur (pour un 1:1) et l'aperçu du dernier
/// message, ce que PostgREST seul ne peut pas exprimer sans N+1 requêtes.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.isGroup,
    this.name,
    this.organizationId,
    this.otherProfileId,
    this.otherUsername,
    this.otherFirstName,
    this.otherLastName,
    this.otherAvatarUrl,
    this.lastMessageContent,
    this.lastMessageSenderId,
    this.lastMessageCreatedAt,
    required this.unread,
  });

  factory ConversationSummary.fromMap(Map<String, dynamic> map) {
    return ConversationSummary(
      id: map['conversation_id'] as String,
      isGroup: map['is_group'] as bool,
      name: map['name'] as String?,
      organizationId: map['organization_id'] as String?,
      otherProfileId: map['other_profile_id'] as String?,
      otherUsername: map['other_username'] as String?,
      otherFirstName: map['other_first_name'] as String?,
      otherLastName: map['other_last_name'] as String?,
      otherAvatarUrl: map['other_avatar_url'] as String?,
      lastMessageContent: map['last_message_content'] as String?,
      lastMessageSenderId: map['last_message_sender_id'] as String?,
      lastMessageCreatedAt: map['last_message_created_at'] != null
          ? DateTime.parse(map['last_message_created_at'] as String)
          : null,
      unread: map['unread'] as bool? ?? false,
    );
  }

  final String id;
  final bool isGroup;
  final String? name;
  final String? organizationId;
  final String? otherProfileId;
  final String? otherUsername;
  final String? otherFirstName;
  final String? otherLastName;
  final String? otherAvatarUrl;
  final String? lastMessageContent;
  final String? lastMessageSenderId;
  final DateTime? lastMessageCreatedAt;
  final bool unread;

  /// `true` pour le groupe automatique d'une organisation (migration 0027) —
  /// distinct d'un groupe classique par exemple pour désactiver l'ajout de
  /// membres à la main.
  bool get isOrganizationGroup => organizationId != null;

  String get displayName {
    if (isGroup) return name ?? 'Groupe';
    if (otherFirstName == null) return otherUsername ?? '…';
    return '$otherFirstName $otherLastName';
  }

  String? get displayAvatarUrl => isGroup ? null : otherAvatarUrl;
}

/// Ce qu'il faut pour afficher l'en-tête de [ChatScreen], transmis via
/// `extra` par tous les points de navigation (liste des conversations,
/// nouvelle conversation directe, nouveau groupe) pour éviter une requête de
/// plus juste pour le titre/l'avatar.
class ChatScreenArgs {
  const ChatScreenArgs({
    required this.conversationId,
    required this.title,
    required this.isGroup,
    this.avatarUrl,
  });

  final String conversationId;
  final String title;
  final bool isGroup;
  final String? avatarUrl;
}

class ConversationParticipant {
  const ConversationParticipant({
    required this.profileId,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
  });

  factory ConversationParticipant.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>;
    return ConversationParticipant(
      profileId: map['profile_id'] as String,
      username: profile['username'] as String,
      firstName: profile['first_name'] as String,
      lastName: profile['last_name'] as String,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }

  final String profileId;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;

  String get fullName => '$firstName $lastName';
}
