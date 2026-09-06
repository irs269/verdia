import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/conversation.dart';
import '../providers/messaging_provider.dart';

/// Liste des conversations (directes + groupes + groupe d'organisation) de
/// l'utilisateur connecté — voir audit/demande utilisateur "système de
/// communication".
class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Nouvelle conversation',
            onPressed: () => context.push('/messages/new'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(conversationsListProvider),
        child: conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(error.toString(), textAlign: TextAlign.center),
              ),
            ],
          ),
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        "Aucune conversation pour l'instant. Ajoute des amis pour commencer à discuter.",
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(conversation: conversation);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final ConversationSummary conversation;

  String _preview() {
    if (conversation.lastMessageContent == null) return 'Aucun message pour l\'instant.';
    return conversation.lastMessageContent!;
  }

  String? _time() {
    final at = conversation.lastMessageCreatedAt;
    if (at == null) return null;
    final now = DateTime.now();
    if (now.difference(at).inDays == 0 && now.day == at.day) {
      return DateFormat('HH:mm').format(at);
    }
    return DateFormat('d MMM', 'fr_FR').format(at);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push(
        '/messages/${conversation.id}',
        extra: ChatScreenArgs(
          conversationId: conversation.id,
          title: conversation.displayName,
          isGroup: conversation.isGroup,
          avatarUrl: conversation.displayAvatarUrl,
        ),
      ),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: conversation.displayAvatarUrl != null
            ? CachedNetworkImageProvider(conversation.displayAvatarUrl!)
            : null,
        child: conversation.displayAvatarUrl == null
            ? Icon(
                conversation.isOrganizationGroup
                    ? Icons.apartment_outlined
                    : (conversation.isGroup ? Icons.groups_outlined : Icons.person),
                color: AppColors.textSecondary,
              )
            : null,
      ),
      title: Text(
        conversation.displayName,
        style: TextStyle(
          fontWeight: conversation.unread ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _preview(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.unread ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: conversation.unread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_time() != null)
            Text(_time()!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (conversation.unread) ...[
            const SizedBox(height: 4),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
          ],
        ],
      ),
    );
  }
}
