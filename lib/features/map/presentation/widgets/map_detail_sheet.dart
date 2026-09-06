import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../actions/domain/eco_action.dart';
import '../../../events/domain/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../reports/domain/environmental_report.dart';

void showActionDetailSheet(BuildContext context, EcoAction action) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: action.category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Text('${action.category.icon} ${action.category.label}',
                style: TextStyle(color: action.category.color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          Text(action.description),
          if (action.city != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(action.city!, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ],
          if (action.impactPoints != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('⭐ +${action.impactPoints} points d\'impact',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    ),
  );
}

void showEventDetailSheet(BuildContext context, Event event) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final actionsState = ref.watch(eventActionsControllerProvider);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE d MMM · HH:mm', 'fr_FR').format(event.startsAt),
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 4),
              Text(event.description),
              if (event.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(event.location!, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${event.participantsCount} participant(s)'
                '${event.targetParticipants != null ? ' / ${event.targetParticipants}' : ''}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: event.isJoinedByMe ? 'Je participe ✓' : 'Je participe',
                outlined: event.isJoinedByMe,
                isLoading: actionsState.isLoading,
                onPressed: () => ref.read(eventActionsControllerProvider.notifier).toggleJoin(
                      event.id,
                      isCurrentlyJoined: event.isJoinedByMe,
                    ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void showReportDetailSheet(BuildContext context, EnvironmentalReport report) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  '${ReportType.icon(report.type)} ${ReportType.label(report.type)}',
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(ReportStatus.label(report.status),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(report.description),
          if (report.photoUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(imageUrl: report.photoUrl!, height: 160, fit: BoxFit.cover),
            ),
          ],
          if (report.city != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(report.city!, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
