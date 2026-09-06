import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../actions/presentation/widgets/impact_summary_row.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../badges/presentation/widgets/badges_tab.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../posts/presentation/widgets/user_posts_tab.dart';
import '../providers/follow_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_content.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwnProfile = currentUserId == userId;
    final profileAsync = ref.watch(profileByIdProvider(userId));

    return Scaffold(
      appBar: AppBar(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (profile) {
          final counts = ref.watch(followCountsProvider(userId)).valueOrNull;
          final eventsJoined = ref.watch(joinedEventsCountProvider(userId)).valueOrNull;

          return ProfileContent(
            profile: profile,
            followers: counts?.followers,
            following: counts?.following,
            eventsJoined: eventsJoined,
            impactSummary: ImpactSummaryRow(profileId: userId),
            actionButton: isOwnProfile
                ? const SizedBox.shrink()
                : _FollowButton(userId: userId),
            tabLabels: const ['Publications', 'Badges'],
            tabViews: [
              UserPostsTab(profileId: userId),
              BadgesTab(profileId: userId),
            ],
          );
        },
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));
    final controllerState = ref.watch(followControllerProvider);

    return isFollowingAsync.when(
      loading: () => const AppButton(label: '…', onPressed: null),
      error: (_, _) => AppButton(
        label: 'Suivre',
        onPressed: () => ref
            .read(followControllerProvider.notifier)
            .toggleFollow(userId, isCurrentlyFollowing: false),
      ),
      data: (isFollowing) => AppButton(
        label: isFollowing ? 'Abonné(e)' : 'Suivre',
        outlined: isFollowing,
        isLoading: controllerState.isLoading,
        onPressed: () => ref
            .read(followControllerProvider.notifier)
            .toggleFollow(userId, isCurrentlyFollowing: isFollowing),
      ),
    );
  }
}
