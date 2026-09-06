import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/environmental_report.dart';

class ReportTile extends StatelessWidget {
  const ReportTile({super.key, required this.report});

  final EnvironmentalReport report;

  Color get _statusColor {
    switch (report.status) {
      case ReportStatus.resolu:
        return AppColors.primary;
      case ReportStatus.rejete:
        return AppColors.error;
      case ReportStatus.enCours:
      case ReportStatus.enVerification:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(
                imageUrl: report.photoUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(ReportType.icon(report.type), style: const TextStyle(fontSize: 22)),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(ReportType.label(report.type),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        ReportStatus.label(report.status),
                        style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    if (report.city != null) report.city!,
                    DateFormat('d MMM', 'fr_FR').format(report.createdAt),
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
