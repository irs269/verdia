import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/app_notification.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final userId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: userId == null
                ? null
                : () => ref.read(notificationRepositoryProvider).markAllAsRead(userId),
            child: const Text('Tout marquer comme lu'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "Tu n'as pas encore de notification.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (!notification.read) {
      ref.read(notificationRepositoryProvider).markAsRead(notification.id);
    }
    switch (notification.type) {
      case 'like':
      case 'comment':
        if (notification.postId != null) {
          context.push('/posts/${notification.postId}/comments');
        }
      case 'follow':
        if (notification.actorId != null) {
          context.push('/users/${notification.actorId}');
        }
      case 'event_joined':
      case 'challenge_joined':
        context.go('/actions');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleTap(context, ref),
      child: Container(
        color: notification.read ? null : AppColors.primary.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceMuted,
              backgroundImage: notification.actorAvatarUrl != null
                  ? CachedNetworkImageProvider(notification.actorAvatarUrl!)
                  : null,
              child: notification.actorAvatarUrl == null
                  ? Text(notification.emoji, style: const TextStyle(fontSize: 18))
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.message),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM HH:mm', 'fr_FR').format(notification.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
