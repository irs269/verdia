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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(eventActionsControllerProvider);
    final isOrganizer = ref.watch(currentUserProvider)?.id == event.organizer.id;

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
                        DateFormat('EEEE d MMM · HH:mm', 'fr_FR').format(event.startsAt),
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
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
