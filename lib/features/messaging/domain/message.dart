/// Un message, sans l'identité de son expéditeur : celle-ci est résolue côté
/// UI via la liste des participants déjà chargée (voir [ChatScreen]), pas
/// par une jointure PostgREST — le flux Realtime des messages ne supporte de
/// toute façon aucune jointure (même limitation que les notifications), donc
/// autant garder une seule forme de message pour l'historique et le direct.
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
}
