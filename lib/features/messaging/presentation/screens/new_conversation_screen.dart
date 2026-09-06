import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/follow_provider.dart';
import '../../domain/conversation.dart';
import '../providers/messaging_provider.dart';

/// Point d'entrée pour démarrer une conversation directe avec un ami, ou
/// créer un groupe — la liste proposée est toujours celle des amis (voir
/// migration 0026 : "on ne peut communiquer qu'avec ses abonnés", devenu
/// "ses amis" une fois l'abonnement rendu réciproque).
class NewConversationScreen extends ConsumerWidget {
  const NewConversationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(currentUserProvider)?.id;
    if (myId == null) return const SizedBox.shrink();

    final friendsState = ref.watch(followListProvider(myId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Créer un groupe',
            onPressed: () => context.push('/messages/new/group'),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (friendsState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (friendsState.profiles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                "Tu n'as pas encore d'amis. Suis quelqu'un pour pouvoir lui écrire.",
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          itemCount: friendsState.profiles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final friend = friendsState.profiles[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceMuted,
                backgroundImage: friend.avatarUrl != null
                    ? CachedNetworkImageProvider(friend.avatarUrl!)
                    : null,
                child: friend.avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
              ),
              title: Text(friend.fullName),
              subtitle: Text('@${friend.username}'),
              onTap: () async {
                final conversationId = await ref
                    .read(messagingControllerProvider.notifier)
                    .openDirectConversation(friend.id);
                if (conversationId == null || !context.mounted) return;
                context.pushReplacement(
                  '/messages/$conversationId',
                  extra: ChatScreenArgs(
                    conversationId: conversationId,
                    title: friend.fullName,
                    isGroup: false,
                    avatarUrl: friend.avatarUrl,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
