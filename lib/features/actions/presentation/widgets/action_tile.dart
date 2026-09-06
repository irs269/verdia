import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/eco_action.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.action});

  final EcoAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: action.category.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(action.category.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  [
                    action.category.label,
                    if (action.city != null) action.city!,
                    DateFormat('d MMM', 'fr_FR').format(action.occurredAt),
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (action.impactPoints != null)
            Text('+${action.impactPoints}',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
