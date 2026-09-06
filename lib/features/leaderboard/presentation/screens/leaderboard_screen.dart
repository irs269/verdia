import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/leaderboard_entry.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Classement'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Global'),
              Tab(text: 'Ma ville'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_GlobalLeaderboard(), _CityLeaderboard()],
        ),
      ),
    );
  }
}

class _GlobalLeaderboard extends ConsumerWidget {
  const _GlobalLeaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(globalLeaderboardProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (entries) => _LeaderboardList(entries: entries),
    );
  }
}

class _CityLeaderboard extends ConsumerWidget {
  const _CityLeaderboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(cityLeaderboardProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (entries) {
        if (entries == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Renseigne ta ville dans ton profil pour voir ce classement.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return _LeaderboardList(entries: entries);
      },
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.entries});

  final List<LeaderboardEntry> entries;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('Personne dans ce classement pour l\'instant.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final currentUserId = ref.watch(currentUserProvider)?.id;

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isMe = entry.id == currentUserId;
        return Container(
          color: isMe ? AppColors.primary.withValues(alpha: 0.06) : null,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  index < 3 ? _medals[index] : '${index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceMuted,
                backgroundImage:
                    entry.avatarUrl != null
                        ? CachedNetworkImageProvider(entry.avatarUrl!)
                        : null,
                child: entry.avatarUrl == null
                    ? const Icon(Icons.person, size: 18, color: AppColors.textSecondary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isMe ? '${entry.fullName} (toi)' : entry.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${entry.totalPoints} pts',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}
