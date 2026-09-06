import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../actions/presentation/widgets/impact_summary_row.dart';
import '../../../badges/presentation/widgets/badges_tab.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../moderation/presentation/providers/moderation_provider.dart';
import '../../../posts/presentation/widgets/saved_posts_tab.dart';
import '../../../posts/presentation/widgets/user_posts_tab.dart';
import '../providers/follow_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_content.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isModerator = ref.watch(isModeratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (isModerator)
            IconButton(
              icon: const Icon(Icons.shield_outlined),
              tooltip: 'Modération',
              onPressed: () => context.push('/moderation'),
            ),
          IconButton(
            icon: const Icon(Icons.apartment_outlined),
            tooltip: 'Organisations',
            onPressed: () => context.push('/organizations'),
          ),
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Classement',
            onPressed: () => context.push('/leaderboard'),
          ),
          IconButton(
            icon: const Icon(Icons.public_outlined),
            tooltip: 'Impact de la communauté',
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Réessayer',
                  onPressed: () => ref.invalidate(currentProfileProvider),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();
          final friendCount = ref.watch(friendCountProvider(profile.id)).valueOrNull;
          final eventsJoined = ref.watch(joinedEventsCountProvider(profile.id)).valueOrNull;
          return ProfileContent(
            profile: profile,
            friends: friendCount,
            eventsJoined: eventsJoined,
            impactSummary: ImpactSummaryRow(profileId: profile.id),
            actionButton: AppButton(
              label: 'Modifier le profil',
              outlined: true,
              onPressed: () => context.push('/profile/edit', extra: profile),
            ),
            tabLabels: const ['Mes actions', 'Mes badges', 'Enregistrés'],
            tabViews: [
              UserPostsTab(profileId: profile.id),
              BadgesTab(profileId: profile.id),
              const SavedPostsTab(),
            ],
          );
        },
      ),
    );
  }
}
