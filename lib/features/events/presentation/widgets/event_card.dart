import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/event.dart';
import '../providers/event_provider.dart';

class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event});

  final Event event;

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cet événement ?'),
        content: const Text('Les participants ne pourront plus le rejoindre. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Annuler l'événement", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(eventActionsControllerProvider.notifier).cancel(event.id);
    }
  }

  bool get _isFinished =>
      DateTime.now().isAfter(event.endsAt ?? event.startsAt) && event.status != 'cancelled';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(eventActionsControllerProvider);
    final isOrganizer = ref.watch(currentUserProvider)?.id == event.organizer.id;
    final isFinished = _isFinished;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isFinished
                            ? 'Terminé · ${DateFormat('d MMM', 'fr_FR').format(event.startsAt)}'
                            : DateFormat('EEEE d MMM · HH:mm', 'fr_FR').format(event.startsAt),
                        style: TextStyle(
                            color: isFinished ? AppColors.textSecondary : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isOrganizer)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                        onSelected: (value) {
                          if (value == 'edit') {
                            context.push('/events/create', extra: event);
                          } else if (value == 'cancel') {
                            _confirmCancel(context, ref);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          PopupMenuItem(
                            value: 'cancel',
                            child: Text("Annuler l'événement",
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                  ],
                ),
                Text(event.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (event.organizerOrgName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.apartment_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Organisé par ${event.organizerOrgName}',
                          style:
                              const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
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
                if (event.progress != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    child: LinearProgressIndicator(
                      value: event.progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (isFinished)
                  _EventBilan(event: event)
                else
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

/// Bilan affiché à la place du bouton "Je participe" une fois l'événement
/// terminé — voir audit, item "Statistiques de campagne".
class _EventBilan extends StatelessWidget {
  const _EventBilan({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final target = event.targetParticipants;
    final reached = target != null && event.participantsCount >= target;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            reached ? Icons.emoji_events_outlined : Icons.groups_outlined,
            size: 18,
            color: reached ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              target != null
                  ? (reached
                      ? 'Objectif atteint : ${event.participantsCount}/$target participant(s)'
                      : '${event.participantsCount}/$target participant(s) — objectif non atteint')
                  : '${event.participantsCount} participant(s) au total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
