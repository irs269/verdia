import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../profile/presentation/widgets/profile_content.dart';
import '../providers/feed_provider.dart';
import 'post_card.dart';

/// Publications d'un utilisateur donné, affichées dans un onglet de profil.
class UserPostsTab extends ConsumerStatefulWidget {
  const UserPostsTab({super.key, required this.profileId});

  final String profileId;

  @override
  ConsumerState<UserPostsTab> createState() => _UserPostsTabState();
}

class _UserPostsTabState extends ConsumerState<UserPostsTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(userPostsProvider(widget.profileId).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userPostsProvider(widget.profileId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.posts.isEmpty) {
      return Center(child: Text(state.error.toString()));
    }

    if (state.posts.isEmpty) {
      return const EmptyTab(emoji: '🌱', message: "Aucune publication pour le moment.");
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(userPostsProvider(widget.profileId).notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: state.posts.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.posts.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final post = state.posts[index];
          final notifier = ref.read(userPostsProvider(widget.profileId).notifier);
          return PostCard(
            post: post,
            onToggleLike: () => notifier.toggleLike(post.id),
            onToggleSave: () => notifier.toggleSave(post.id),
          );
        },
      ),
    );
  }
}
