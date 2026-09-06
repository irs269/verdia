import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../actions/domain/eco_action.dart';
import '../../../actions/presentation/providers/action_provider.dart';
import '../../domain/content_report.dart';
import '../providers/moderation_provider.dart';

/// Accessible uniquement aux profils `role = 'moderator'` (voir
/// [isModeratorProvider] et migration 0015) — l'entrée n'apparaît sur
/// [ProfileScreen] que pour eux, et les policies RLS refusent de toute façon
/// toute écriture côté serveur pour les autres.
class ModerationDashboardScreen extends ConsumerWidget {
  const ModerationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modération'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Signalements'),
            Tab(text: 'Actions publiées'),
          ]),
        ),
        body: const TabBarView(
          children: [_ReportsTab(), _ActionsTab()],
        ),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  Future<void> _resolve(WidgetRef ref, BuildContext context, Report report, String newStatus, String contentAction) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(moderationControllerProvider.notifier).resolveReport(
          reportId: report.id,
          newStatus: newStatus,
          contentAction: contentAction,
        );
    if (!context.mounted) return;
    final error = ref.read(moderationControllerProvider).error;
    messenger.showSnackBar(
      SnackBar(content: Text(success ? 'Signalement traité.' : error.toString())),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(pendingReportsProvider);
    final controllerState = ref.watch(moderationControllerProvider);

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(
            child: Text('Aucun signalement en attente.',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final report = reports[index];
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Text(ReportReason.label(report.reason),
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.targetType == ReportTargetType.post ? 'Publication' : 'Commentaire',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(DateFormat('d MMM', 'fr_FR').format(report.createdAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  if (report.description != null) ...[
                    const SizedBox(height: 6),
                    Text(report.description!),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controllerState.isLoading
                              ? null
                              : () => _resolve(ref, context, report, ReportStatus.dismissed, 'no_action'),
                          child: const Text('Ignorer'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: controllerState.isLoading
                              ? null
                              : () => _resolve(
                                  ref, context, report, ReportStatus.reviewed, 'content_removed'),
                          child: const Text('Marquer traité'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ActionsTab extends ConsumerWidget {
  const _ActionsTab();

  Future<void> _confirmReject(BuildContext context, WidgetRef ref, EcoAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter cette action ?'),
        content: Text(
          '"${action.title}" sera marquée rejetée${action.impactPoints != null ? ' et les ${action.impactPoints} points déjà crédités seront retirés' : ''}. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Rejeter', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(moderationControllerProvider.notifier).rejectAction(action.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(success ? 'Action rejetée.' : 'La modération a échoué.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(actionsListProvider);

    if (actionsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (actionsState.actions.isEmpty) {
      return const Center(
        child: Text('Aucune action publiée.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: actionsState.actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final action = actionsState.actions[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${action.category.label} · ${DateFormat('d MMM', 'fr_FR').format(action.occurredAt)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _confirmReject(context, ref, action),
                child: const Text('Rejeter', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
    );
  }
}
