import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/event.dart';
import '../providers/event_provider.dart';

class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(eventActionsControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.coverUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(imageUrl: event.coverUrl!, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE d MMM · HH:mm', 'fr_FR').format(event.startsAt),
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Text(event.location!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 4),
                Text(
                  '${event.participantsCount} participant(s)'
                  '${event.targetParticipants != null ? ' / ${event.targetParticipants}' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
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
          ),
        ],
      ),
    );
  }
}
