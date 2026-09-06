import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../actions/domain/eco_action.dart';
import '../../../moderation/domain/content_report.dart';
import '../../../moderation/presentation/widgets/report_content_sheet.dart';
import '../../domain/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleSave,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
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
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'report', child: Text('Signaler')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (post.action != null) ...[
            _CategoryBadge(action: post.action!),
            const SizedBox(height: AppSpacing.sm),
            Text(post.action!.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 2),
            Text(post.action!.description),
            if (post.action!.quantityLabel != null) ...[
              const SizedBox(height: 4),
              Text('📊 ${post.action!.quantityLabel} · ${post.action!.participantsCount} participant(s)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ] else
            Text(post.content),
          if (post.media.isNotEmpty) ...[
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
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bientôt disponible 🌱')),
                ),
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
