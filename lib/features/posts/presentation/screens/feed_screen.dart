import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../messaging/presentation/providers/messaging_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../data/post_repository.dart';
import '../providers/feed_provider.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final unreadConversations = ref.watch(unreadConversationsCountProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('VERDIA', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/search'),
              tooltip: 'Rechercher',
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () => context.push('/messages'),
              tooltip: 'Messages',
              icon: Badge(
                label: Text('$unreadConversations'),
                isLabelVisible: unreadConversations > 0,
                child: const Icon(Icons.chat_bubble_outline),
              ),
            ),
            IconButton(
              onPressed: () => context.push('/notifications'),
              tooltip: 'Notifications',
              icon: Badge(
                label: Text('$unreadCount'),
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: l10n.feedForYouTab),
              Tab(text: l10n.feedFollowingTab),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FeedList(type: FeedType.forYou),
            _FeedList(type: FeedType.following),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends ConsumerStatefulWidget {
  const _FeedList({required this.type});

  final FeedType type;

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedProvider(widget.type).notifier).loadMore();
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
    super.build(context);
    final state = ref.watch(feedProvider(widget.type));
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.read(feedProvider(widget.type).notifier).refresh(),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.posts.isEmpty) {
      final message =
          widget.type == FeedType.forYou ? l10n.feedEmptyForYou : l10n.feedEmptyFollowing;
      // `ListView` scrollable pour que le tiré-pour-rafraîchir marche même à
      // vide — cet onglet reste vivant en arrière-plan (IndexedStack/TabBarView).
      return RefreshIndicator(
        onRefresh: () => ref.read(feedProvider(widget.type).notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider(widget.type).notifier).refresh(),
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
            onToggleLike: () =>
                ref.read(feedProvider(widget.type).notifier).toggleLike(post.id),
            onToggleSave: () =>
                ref.read(feedProvider(widget.type).notifier).toggleSave(post.id),
            onDelete: () =>
                ref.read(feedProvider(widget.type).notifier).removePost(post.id),
            onEdit: (newContent) =>
                ref.read(feedProvider(widget.type).notifier).editPost(post.id, newContent),
          );
        },
      ),
    );
  }
}
