import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/widgets/report_content_sheet.dart';
import '../providers/comments_provider.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(commentsProvider(widget.postId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    await ref.read(commentControllerProvider.notifier).addComment(widget.postId, text);
  }

  @override
  Widget build(BuildContext context) {
    final commentsState = ref.watch(commentsProvider(widget.postId));
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final controllerState = ref.watch(commentControllerProvider);

    ref.listen(commentControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Commentaires')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  if (commentsState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (commentsState.error != null && commentsState.comments.isEmpty) {
                    return Center(child: Text(commentsState.error.toString()));
                  }
                  final comments = commentsState.comments;
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun commentaire pour le moment.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: comments.length + (commentsState.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index >= comments.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final comment = comments[index];
                      final isMine = comment.author.id == currentUserId;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.surfaceMuted,
                            backgroundImage: comment.author.avatarUrl != null
                                ? CachedNetworkImageProvider(comment.author.avatarUrl!)
                                : null,
                            child: comment.author.avatarUrl == null
                                ? const Icon(Icons.person,
                                    size: 16, color: AppColors.textSecondary)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('@${comment.author.username}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('d MMM HH:mm', 'fr_FR')
                                          .format(comment.createdAt),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(comment.content),
                              ],
                            ),
                          ),
                          if (isMine)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              color: AppColors.textSecondary,
                              tooltip: 'Supprimer',
                              onPressed: () => ref
                                  .read(commentControllerProvider.notifier)
                                  .deleteComment(widget.postId, comment.id),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.flag_outlined, size: 18),
                              color: AppColors.textSecondary,
                              tooltip: 'Signaler',
                              onPressed: () => showReportContentSheet(
                                context,
                                targetType: ReportTargetType.comment,
                                targetId: comment.id,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: controllerState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                    tooltip: 'Envoyer',
                    onPressed: controllerState.isLoading ? null : _send,
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
