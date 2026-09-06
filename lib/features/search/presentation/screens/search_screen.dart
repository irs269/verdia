import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/profile_list_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../challenges/presentation/widgets/challenge_card.dart';
import '../../../events/presentation/widgets/event_card.dart';
import '../../../posts/presentation/providers/feed_provider.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              border: InputBorder.none,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Publications'),
              Tab(text: 'Événements'),
              Tab(text: 'Défis'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProfileResults(),
            _PostResults(),
            _EventResults(),
            _ChallengeResults(),
          ],
        ),
      ),
    );
  }
}

class _EmptyQuery extends StatelessWidget {
  const _EmptyQuery();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Tape au moins 2 caractères pour rechercher.',
          style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _ProfileResults extends ConsumerWidget {
  const _ProfileResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.trim().length < 2) return const _EmptyQuery();

    final resultsAsync = ref.watch(profileSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (profiles) {
        if (profiles.isEmpty) {
          return const Center(
            child: Text('Aucun utilisateur trouvé.',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => ProfileListTile(profile: profiles[index]),
        );
      },
    );
  }
}

class _PostResults extends ConsumerWidget {
  const _PostResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.trim().length < 2) return const _EmptyQuery();

    final resultsAsync = ref.watch(postSearchResultsProvider(query));
    final userId = ref.watch(currentUserProvider)?.id;

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Text('Aucune publication trouvée.',
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
                ref.invalidate(postSearchResultsProvider(query));
              },
              onToggleSave: () async {
                if (userId == null) return;
                final repo = ref.read(postRepositoryProvider);
                if (post.isSavedByMe) {
                  await repo.unsave(post.id, userId);
                } else {
                  await repo.save(post.id, userId);
                }
                ref.invalidate(postSearchResultsProvider(query));
              },
              onDelete: () => ref.invalidate(postSearchResultsProvider(query)),
              onEdit: (_) => ref.invalidate(postSearchResultsProvider(query)),
            );
          },
        );
      },
    );
  }
}

class _EventResults extends ConsumerWidget {
  const _EventResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.trim().length < 2) return const _EmptyQuery();

    final resultsAsync = ref.watch(eventSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Text('Aucun événement trouvé.',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => EventCard(event: events[index]),
        );
      },
    );
  }
}

class _ChallengeResults extends ConsumerWidget {
  const _ChallengeResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    if (query.trim().length < 2) return const _EmptyQuery();

    final resultsAsync = ref.watch(challengeSearchResultsProvider(query));
    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (challenges) {
        if (challenges.isEmpty) {
          return const Center(
            child: Text('Aucun défi trouvé.', style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: challenges.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => ChallengeCard(challenge: challenges[index]),
        );
      },
    );
  }
}
