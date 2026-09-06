import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/challenge.dart';
import '../providers/challenge_provider.dart';

class ChallengeCard extends ConsumerWidget {
  const ChallengeCard({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(challengeActionsControllerProvider);
    final formattedCurrent = challenge.currentValue == challenge.currentValue.roundToDouble()
        ? challenge.currentValue.toInt().toString()
        : challenge.currentValue.toStringAsFixed(1);
    final formattedTarget = challenge.targetValue == challenge.targetValue.roundToDouble()
        ? challenge.targetValue.toInt().toString()
        : challenge.targetValue.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${challenge.category?.icon ?? '🌍'} ${challenge.title}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (challenge.organizerOrgName != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.apartment_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Organisé par ${challenge.organizerOrgName}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(challenge.description, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text('$formattedCurrent / $formattedTarget ${challenge.unit}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation(challenge.category?.color ?? AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${challenge.participantsCount} participant(s)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(
                challenge.daysRemaining > 0
                    ? '${challenge.daysRemaining} jour(s) restant(s)'
                    : 'Dernier jour',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: challenge.isJoinedByMe ? 'Je participe ✓' : 'Rejoindre',
            outlined: challenge.isJoinedByMe,
            isLoading: actionsState.isLoading,
            onPressed: () => ref.read(challengeActionsControllerProvider.notifier).toggleJoin(
                  challenge.id,
                  isCurrentlyJoined: challenge.isJoinedByMe,
                ),
          ),
        ],
      ),
    );
  }
}
