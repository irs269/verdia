import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';

const _messagesPageSize = 30;

class MessagingRepository {
  MessagingRepository(this._client);

  final SupabaseClient _client;

  /// Liste des conversations de l'utilisateur connecté, dernier message
  /// d'abord — voir la fonction RPC `list_my_conversations` (migration 0027).
  Future<List<ConversationSummary>> fetchConversations() async {
    try {
      final data = await _client.rpc('list_my_conversations');
      return (data as List)
          .map((e) => ConversationSummary.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les conversations.');
    }
  }

  /// Réutilise ou crée la conversation directe avec [otherId] — la fonction
  /// RPC refuse si les deux ne sont pas amis (voir migration 0027).
  Future<String> getOrCreateDirectConversation(String otherId) async {
    try {
      final id = await _client
          .rpc('get_or_create_direct_conversation', params: {'p_other_id': otherId});
      return id as String;
    } on PostgrestException catch (e) {
      throw AppException(e.code == '42501'
          ? 'Vous ne pouvez discuter qu\'avec vos amis.'
          : "Impossible de démarrer la conversation.");
    } catch (_) {
      throw const AppException("Impossible de démarrer la conversation.");
    }
  }

  Future<String> createGroup({required String name, required List<String> memberIds}) async {
    try {
      final id = await _client.rpc('create_group_conversation', params: {
        'p_name': name,
        'p_member_ids': memberIds,
      });
      return id as String;
    } catch (_) {
      throw const AppException("La création du groupe a échoué.");
    }
  }

  Future<void> addGroupMember({
    required String conversationId,
    required String memberId,
  }) async {
    try {
      await _client.rpc('add_group_member', params: {
        'p_conversation_id': conversationId,
        'p_member_id': memberId,
      });
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (_) {
      throw const AppException("L'ajout du membre a échoué.");
    }
  }

  Future<List<ConversationParticipant>> fetchMembers(String conversationId) async {
    try {
      final data = await _client
          .from('conversation_participants')
          .select('profile_id, profiles(username, first_name, last_name, avatar_url)')
          .eq('conversation_id', conversationId);
      return (data as List)
          .map((e) => ConversationParticipant.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Best-effort : ne bloque jamais l'ouverture d'une conversation si la
  /// mise à jour du badge "non lu" échoue.
  Future<void> markRead(String conversationId) async {
    try {
      await _client.rpc('mark_conversation_read', params: {'p_conversation_id': conversationId});
    } catch (_) {
      // Non bloquant.
    }
  }

  Future<List<Message>> fetchMessages({
    required String conversationId,
    DateTime? before,
  }) async {
    try {
      var query =
          _client.from('messages').select().eq('conversation_id', conversationId);
      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      final data =
          await query.order('created_at', ascending: false).limit(_messagesPageSize);
      return (data as List).map((e) => Message.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les messages.');
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (_) {
      throw const AppException("L'envoi du message a échoué.");
    }
  }

  /// Flux temps réel des messages d'une conversation — même pattern que
  /// [NotificationRepository.streamFor] : pas de jointure possible côté
  /// Realtime, l'identité de l'expéditeur est résolue côté UI via la liste
  /// des participants déjà chargée.
  Stream<List<Message>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((rows) => rows.map(Message.fromMap).toList());
  }
}
