import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../providers/action_provider.dart';

/// Nombre d'actions vérifiées par catégorie pour un profil — n'affiche rien
/// tant qu'aucune action n'a encore été publiée (pas de zéros fictifs).
class ImpactSummaryRow extends ConsumerWidget {
  const ImpactSummaryRow({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(actionCategoriesProvider);
    final countsAsync = ref.watch(userActionCountsProvider(profileId));

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) => countsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (counts) {
          final entries = categories
              .where((c) => (counts[c.code] ?? 0) > 0)
              .map((c) => MapEntry(c, counts[c.code]!))
              .toList();
          if (entries.isEmpty) return const SizedBox.shrink();

          return Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.key.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  '${entry.key.icon} ${entry.value}',
                  style: TextStyle(color: entry.key.color, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
