import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/eco_badge.dart';
import '../providers/badge_provider.dart';

class BadgesTab extends ConsumerWidget {
  const BadgesTab({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider(profileId));

    return badgesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (badges) {
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return GestureDetector(
              onTap: () => _showBadgeDialog(context, badge),
              child: Opacity(
                opacity: badge.isUnlocked ? 1 : 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: badge.isUnlocked
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Text(badge.icon, style: const TextStyle(fontSize: 26)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBadgeDialog(BuildContext context, EcoBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${badge.icon} ${badge.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: AppSpacing.sm),
            Text(
              badge.isUnlocked
                  ? 'Débloqué le ${DateFormat('d MMM yyyy', 'fr_FR').format(badge.earnedAt!)}'
                  : 'Pas encore débloqué',
              style: TextStyle(
                color: badge.isUnlocked ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
