import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../profile/presentation/widgets/profile_content.dart';
import '../providers/feed_provider.dart';
import 'post_card.dart';

/// Publications enregistrées par l'utilisateur connecté ("bookmark"), triées
/// par date d'enregistrement. Contrairement à [UserPostsTab], un post retiré
/// des favoris disparaît immédiatement de cette liste.
class SavedPostsTab extends ConsumerStatefulWidget {
  const SavedPostsTab({super.key});

  @override
  ConsumerState<SavedPostsTab> createState() => _SavedPostsTabState();
}

class _SavedPostsTabState extends ConsumerState<SavedPostsTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(savedPostsProvider.notifier).loadMore();
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
    final state = ref.watch(savedPostsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifier = ref.read(savedPostsProvider.notifier);

    if (state.error != null && state.posts.isEmpty) {
      return Center(child: Text(state.error.toString()));
    }

    if (state.posts.isEmpty) {
      // Un `ListView` scrollable (même vide) est nécessaire pour que le
      // tiré-pour-rafraîchir fonctionne : cet onglet reste vivant tant que
      // le profil l'est (TabBarView le garde en cache), donc c'est le seul
      // moyen de voir apparaître un post qu'on vient d'enregistrer sans
      // relancer l'appli.
      return RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyTab(emoji: '🔖', message: "Rien d'enregistré pour l'instant."),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
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
