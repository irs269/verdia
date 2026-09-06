import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/content_report.dart';
import '../providers/moderation_provider.dart';

/// Ouvre la feuille de signalement d'un post ou d'un commentaire. Affiche
/// elle-même un `SnackBar` de confirmation/erreur — l'appelant n'a rien à
/// faire d'autre que déclencher l'ouverture.
void showReportContentSheet(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
    ),
    builder: (context) => _ReportContentSheet(targetType: targetType, targetId: targetId),
  );
}

class _ReportContentSheet extends ConsumerStatefulWidget {
  const _ReportContentSheet({required this.targetType, required this.targetId});

  final ReportTargetType targetType;
  final String targetId;

  @override
  ConsumerState<_ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends ConsumerState<_ReportContentSheet> {
  final _descriptionController = TextEditingController();
  String _reason = ReportReason.spam;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final success = await ref.read(reportContentControllerProvider.notifier).submit(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reason: _reason,
          description:
              _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );

    if (!mounted) return;
    final error = ref.read(reportContentControllerProvider).error;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Signalement envoyé, merci.' : error.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(reportContentControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.targetType == ReportTargetType.post
                ? 'Signaler cette publication'
                : 'Signaler ce commentaire',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: ReportReason.all.map((reason) {
              return ChoiceChip(
                label: Text(ReportReason.label(reason)),
                selected: _reason == reason,
                onSelected: (_) => setState(() => _reason = reason),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Détails (optionnel)',
            hint: 'Ajoute un contexte si besoin...',
            controller: _descriptionController,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Envoyer le signalement',
            isLoading: controllerState.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
