import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/profile.dart';

/// Corps visuel commun aux écrans "mon profil" et "profil d'un membre" :
/// en-tête (avatar, identité, stats) + onglets défilables avec le contenu
/// qui reste visible pendant le scroll.
class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.profile,
    required this.followers,
    required this.following,
    required this.actionButton,
    required this.tabLabels,
    required this.tabViews,
    this.impactSummary,
  });

  final Profile profile;
  final int? followers;
  final int? following;
  final Widget actionButton;
  final Widget? impactSummary;
  final List<String> tabLabels;
  final List<Widget> tabViews;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabLabels.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.surfaceMuted,
                    backgroundImage: profile.avatarUrl != null
                        ? CachedNetworkImageProvider(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? const Icon(Icons.person, size: 44, color: AppColors.textSecondary)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profile.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('@${profile.username}',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  if (profile.location != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(profile.location!,
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                  if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(profile.bio!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Stat(emoji: '⭐', value: '${profile.totalPoints}', label: 'points'),
                      const SizedBox(width: AppSpacing.lg),
                      _Stat(emoji: '🏆', value: '${profile.level}', label: 'niveau'),
                      if (following != null) ...[
                        const SizedBox(width: AppSpacing.lg),
                        GestureDetector(
                          onTap: () => context.push('/users/${profile.id}/following'),
                          child: _Stat(value: '$following', label: 'abonnements'),
                        ),
                      ],
                      if (followers != null) ...[
                        const SizedBox(width: AppSpacing.lg),
                        GestureDetector(
                          onTap: () => context.push('/users/${profile.id}/followers'),
                          child: _Stat(value: '$followers', label: 'abonnés'),
                        ),
                      ],
                    ],
                  ),
                  if (impactSummary != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    impactSummary!,
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  actionButton,
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: tabLabels.map((e) => Tab(text: e)).toList(),
              ),
            ),
          ),
        ],
        body: TabBarView(children: tabViews),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({this.emoji, required this.value, required this.label});

  final String? emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji != null ? '$emoji $value' : value,
            style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class EmptyTab extends StatelessWidget {
  const EmptyTab({super.key, required this.emoji, required this.message});

  final String emoji;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
