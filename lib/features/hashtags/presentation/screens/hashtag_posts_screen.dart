import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../posts/presentation/providers/feed_provider.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../providers/hashtag_provider.dart';

/// Liste des publications portant un hashtag donné — voir audit, item
/// "Hashtags". Accessible en tapant `#un-mot` dans une publication ou depuis
/// l'onglet "Hashtags" de la recherche.
class HashtagPostsScreen extends ConsumerWidget {
  const HashtagPostsScreen({super.key, required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsByHashtagProvider(tag));
    final userId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(title: Text('#$tag')),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text('Aucune publication avec ce hashtag pour l\'instant.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onToggleLike: () async {
                  if (userId == null) return;
                  final repo = ref.read(postRepositoryProvider);
                  if (post.isLikedByMe) {
                    await repo.unlike(post.id, userId);
                  } else {
                    await repo.like(post.id, userId);
                  }
                  ref.invalidate(postsByHashtagProvider(tag));
                },
                onToggleSave: () async {
                  if (userId == null) return;
                  final repo = ref.read(postRepositoryProvider);
                  if (post.isSavedByMe) {
                    await repo.unsave(post.id, userId);
                  } else {
                    await repo.save(post.id, userId);
                  }
                  ref.invalidate(postsByHashtagProvider(tag));
                },
                onDelete: () => ref.invalidate(postsByHashtagProvider(tag)),
                onEdit: (_) => ref.invalidate(postsByHashtagProvider(tag)),
              );
            },
          );
        },
      ),
    );
  }
}
