import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/hashtag_text.dart';
import '../../../actions/domain/eco_action.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/widgets/report_content_sheet.dart';
import '../../domain/post.dart';
import '../providers/feed_provider.dart';

class PostCard extends ConsumerWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleSave,
    this.onDelete,
    this.onEdit,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;

  /// Appelé une fois la publication effectivement supprimée côté serveur,
  /// pour que l'écran appelant la retire de sa propre liste. `null` désactive
  /// silencieusement l'option "Supprimer" (ex. résultats de recherche
  /// affichant le post d'un tiers).
  final VoidCallback? onDelete;

  /// Appelé avec le nouveau texte une fois la modification effectivement
  /// enregistrée côté serveur, pour que l'écran appelant mette à jour sa
  /// propre liste. `null` désactive silencieusement l'option "Modifier".
  final void Function(String newContent)? onEdit;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette publication ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(postRepositoryProvider).deletePost(post.id);
      onDelete?.call();
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Réservé aux publications texte libre : un post lié à une action affiche
  /// `action.title`/`description`, jamais `content`, donc l'éditer n'aurait
  /// aucun effet visible (voir [Post.action]/[PostCard.build]).
  Future<void> _editPost(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: post.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la publication'),
        content: TextField(controller: controller, maxLines: 5, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.of(context).pop(text);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newContent == null || newContent == post.content || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(postRepositoryProvider).updatePost(post.id, newContent);
      onEdit?.call(newContent);
    } on AppException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Pas de page web publique par post (l'appli exige une connexion) : on
  /// partage donc le texte de l'action/publication, pas un lien.
  void _share(BuildContext context) {
    final text = post.action != null
        ? '🌱 ${post.author.fullName} a partagé une action VERDIA : '
            '"${post.action!.title}"\n\n${post.action!.description}'
        : '🌱 ${post.author.fullName} via VERDIA :\n\n${post.content}';

    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    Share.share(text, subject: 'VERDIA', sharePositionOrigin: origin);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = ref.watch(currentUserProvider)?.id == post.author.id;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/users/${post.author.id}'),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage: post.author.avatarUrl != null
                      ? CachedNetworkImageProvider(post.author.avatarUrl!)
                      : null,
                  child: post.author.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        [
                          '@${post.author.username}',
                          if (post.location != null) post.location!,
                        ].join(' · '),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  _relativeDate(post.createdAt),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'report') {
                      showReportContentSheet(
                        context,
                        targetType: ReportTargetType.post,
                        targetId: post.id,
                      );
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref);
                    } else if (value == 'edit') {
                      _editPost(context, ref);
                    }
                  },
                  itemBuilder: (context) => isMine
                      ? [
                          if (post.action == null)
                            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
                          ),
                        ]
                      : const [
                          PopupMenuItem(value: 'report', child: Text('Signaler')),
                        ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (post.action != null) ...[
            Row(
              children: [
                _CategoryBadge(action: post.action!),
                if (post.action!.status != 'verified') ...[
                  const SizedBox(width: AppSpacing.sm),
                  _ActionStatusBadge(status: post.action!.status),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(post.action!.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            HashtagText(post.action!.description),
            if (post.action!.quantityLabel != null) ...[
              const SizedBox(height: 4),
              Text('📊 ${post.action!.quantityLabel} · ${post.action!.participantsCount} participant(s)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ] else
            HashtagText(post.content),
          if (post.media.any((m) => m.label != null)) ...[
            const SizedBox(height: AppSpacing.sm),
            _BeforeAfterPhotos(media: post.media),
          ] else if (post.media.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(imageUrl: post.media.first.url, fit: BoxFit.cover),
              ),
            ),
            if (post.media.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${post.media.length - 1} photo(s)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
          ],
          if (post.action?.impactPoints != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '⭐ +${post.action!.impactPoints} points d\'impact',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ActionIcon(
                icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.isLikedByMe ? Colors.redAccent : AppColors.textSecondary,
                label: '${post.likeCount}',
                semanticLabel: post.isLikedByMe ? 'Ne plus aimer' : 'Aimer',
                onTap: onToggleLike,
              ),
              const SizedBox(width: AppSpacing.lg),
              _ActionIcon(
                icon: Icons.mode_comment_outlined,
                color: AppColors.textSecondary,
                label: '${post.commentCount}',
                semanticLabel: 'Commenter',
                onTap: () => context.push('/posts/${post.id}/comments'),
              ),
              const SizedBox(width: AppSpacing.lg),
              _ActionIcon(
                icon: Icons.share_outlined,
                color: AppColors.textSecondary,
                semanticLabel: 'Partager',
                onTap: () => _share(context),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  post.isSavedByMe ? Icons.bookmark : Icons.bookmark_border,
                  color: post.isSavedByMe ? AppColors.primary : AppColors.textSecondary,
                ),
                tooltip: post.isSavedByMe ? 'Retirer des enregistrements' : 'Enregistrer',
                onPressed: onToggleSave,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} j';
    return DateFormat('d MMM', 'fr_FR').format(date);
  }
}

/// Une action nouvellement créée est 'pending' jusqu'à validation par un
/// modérateur (migration 0017) — les points ne s'affichent qu'une fois
/// 'verified'. Masqué pour les actions déjà vérifiées (cas normal).
class _ActionStatusBadge extends StatelessWidget {
  const _ActionStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'pending';
    final color = isPending ? AppColors.warning : AppColors.error;
    final label = isPending ? '⏳ En attente de validation' : '✕ Rejetée';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.action});

  final EcoAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        '${action.category.icon} ${action.category.label}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _BeforeAfterPhotos extends StatelessWidget {
  const _BeforeAfterPhotos({required this.media});

  final List<PostMedia> media;

  @override
  Widget build(BuildContext context) {
    PostMedia? findByLabel(String label) {
      for (final m in media) {
        if (m.label == label) return m;
      }
      return null;
    }

    final avant = findByLabel('avant');
    final apres = findByLabel('apres');

    return Row(
      children: [
        if (avant != null) Expanded(child: _LabeledPhoto(label: 'Avant', media: avant)),
        if (avant != null && apres != null) const SizedBox(width: AppSpacing.sm),
        if (apres != null) Expanded(child: _LabeledPhoto(label: 'Après', media: apres)),
      ],
    );
  }
}

class _LabeledPhoto extends StatelessWidget {
  const _LabeledPhoto({required this.label, required this.media});

  final String label;
  final PostMedia media;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(imageUrl: media.url, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semanticLabel,
    this.label,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label!, style: TextStyle(color: color, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
