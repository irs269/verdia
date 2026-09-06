import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/conversation.dart';
import '../providers/messaging_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.args});

  final ChatScreenArgs args;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(messagingRepositoryProvider).markRead(widget.args.conversationId),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    // Rafraîchit l'aperçu/le badge "non lu" de la liste au retour — le flux
    // temps réel des messages ne met pas à jour `list_my_conversations`.
    ref.invalidate(conversationsListProvider);
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final content = _controller.text;
    if (content.trim().isEmpty) return;
    _controller.clear();
    await ref.read(messagingControllerProvider.notifier).sendMessage(
          conversationId: widget.args.conversationId,
          content: content,
        );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.args.conversationId));
    final membersAsync = ref.watch(conversationMembersProvider(widget.args.conversationId));
    final myId = ref.watch(currentUserProvider)?.id;
    final members = {
      for (final m in membersAsync.valueOrNull ?? []) m.profileId: m,
    };

    ref.listen(chatMessagesStreamProvider(widget.args.conversationId), (previous, next) {
      final count = next.valueOrNull?.length ?? 0;
      if (count > _lastMessageCount) {
        _lastMessageCount = count;
        _scrollToBottom();
        ref.read(messagingRepositoryProvider).markRead(widget.args.conversationId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceMuted,
              backgroundImage: widget.args.avatarUrl != null
                  ? CachedNetworkImageProvider(widget.args.avatarUrl!)
                  : null,
              child: widget.args.avatarUrl == null
                  ? Icon(widget.args.isGroup ? Icons.groups_outlined : Icons.person,
                      size: 18, color: AppColors.textSecondary)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(widget.args.title,
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        actions: [
          if (widget.args.isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Membres du groupe',
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => _GroupMembersSheet(conversationId: widget.args.conversationId),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('Dis bonjour 👋',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == myId;
                      final sender = members[message.senderId];
                      return _MessageBubble(
                        content: message.content,
                        time: DateFormat('HH:mm').format(message.createdAt),
                        isMine: isMine,
                        senderName: widget.args.isGroup && !isMine ? sender?.fullName : null,
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Écrire un message…',
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.content,
    required this.time,
    required this.isMine,
    this.senderName,
  });

  final String content;
  final String time;
  final bool isMine;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 2),
              child: Text(senderName!,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isMine ? AppColors.primary : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupMembersSheet extends ConsumerWidget {
  const _GroupMembersSheet({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(conversationMembersProvider(conversationId));
    return SafeArea(
      child: membersAsync.when(
        loading: () => const SizedBox(
            height: 120, child: Center(child: CircularProgressIndicator())),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(error.toString()),
        ),
        data: (members) => ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Membres du groupe', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final member in members)
              ListTile(
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/users/${member.profileId}');
                },
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage: member.avatarUrl != null
                      ? CachedNetworkImageProvider(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.textSecondary)
                      : null,
                ),
                title: Text(member.fullName),
                subtitle: Text('@${member.username}'),
              ),
          ],
        ),
      ),
    );
  }
}
