import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/messaging_repository.dart';
import '../../domain/conversation.dart';
import '../../domain/message.dart';

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(SupabaseService.client);
});

/// Signal réémis à chaque changement sur `messages` (voir
/// [MessagingRepository.streamMyConversationsChanged]) — sans ça,
/// [conversationsListProvider] ne serait jamais réévalué tant qu'un widget
/// (ex. le badge de l'AppBar du fil) le garde en vie, puisqu'un
/// `FutureProvider.autoDispose` ne se recalcule qu'à la création d'une
/// nouvelle instance, jamais tout seul.
final _conversationsChangedProvider = StreamProvider.autoDispose<void>((ref) {
  return ref.watch(messagingRepositoryProvider).streamMyConversationsChanged();
});

final conversationsListProvider = FutureProvider.autoDispose<List<ConversationSummary>>((ref) {
  ref.watch(_conversationsChangedProvider);
  return ref.watch(messagingRepositoryProvider).fetchConversations();
});

/// Nombre de conversations avec un message non lu — pour le badge de
/// l'icône "Messages" du fil.
final unreadConversationsCountProvider = Provider.autoDispose<int>((ref) {
  final conversations = ref.watch(conversationsListProvider).valueOrNull ?? const [];
  return conversations.where((c) => c.unread).length;
});

final conversationMembersProvider =
    FutureProvider.autoDispose.family<List<ConversationParticipant>, String>((ref, conversationId) {
  return ref.watch(messagingRepositoryProvider).fetchMembers(conversationId);
});

/// Les 50 derniers messages d'une conversation, mis à jour en direct — même
/// choix assumé que les notifications (Phase 7/section 10 de l'audit) :
/// un flux Realtime ne se paginant pas nativement, on accepte une fenêtre
/// bornée plutôt qu'un historique complet pour ce MVP.
final chatMessagesStreamProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, conversationId) {
  return ref.watch(messagingRepositoryProvider).streamMessages(conversationId);
});

final messagingControllerProvider =
    AsyncNotifierProvider.autoDispose<MessagingController, void>(MessagingController.new);

class MessagingController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage({required String conversationId, required String content}) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || content.trim().isEmpty) return;

    state = await AsyncValue.guard(() => ref.read(messagingRepositoryProvider).sendMessage(
          conversationId: conversationId,
          senderId: userId,
          content: content.trim(),
        ));
  }

  /// Retourne l'id de la conversation en cas de succès, `null` sinon (par
  /// exemple si [otherId] n'est pas un ami).
  Future<String?> openDirectConversation(String otherId) async {
    state = const AsyncLoading();
    String? conversationId;
    state = await AsyncValue.guard(() async {
      conversationId =
          await ref.read(messagingRepositoryProvider).getOrCreateDirectConversation(otherId);
    });
    return state.hasError ? null : conversationId;
  }

  Future<String?> createGroup({required String name, required List<String> memberIds}) async {
    state = const AsyncLoading();
    String? conversationId;
    state = await AsyncValue.guard(() async {
      conversationId = await ref
          .read(messagingRepositoryProvider)
          .createGroup(name: name, memberIds: memberIds);
    });
    if (!state.hasError) ref.invalidate(conversationsListProvider);
    return state.hasError ? null : conversationId;
  }

  Future<bool> addGroupMember({required String conversationId, required String memberId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(messagingRepositoryProvider)
        .addGroupMember(conversationId: conversationId, memberId: memberId));
    if (!state.hasError) ref.invalidate(conversationMembersProvider(conversationId));
    return !state.hasError;
  }
}
