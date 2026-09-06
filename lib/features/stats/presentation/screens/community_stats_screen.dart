import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/stats_provider.dart';

/// Vue d'impact cumulé de toute la communauté VERDIA — voir audit, item
/// "Statistiques globales de VERDIA".
class CommunityStatsScreen extends ConsumerWidget {
  const CommunityStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(communityStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Impact de la communauté')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(communityStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                "Ce que VERDIA a permis d'accomplir, ensemble.",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    icon: Icons.groups_outlined,
                    value: '${stats.membersCount}',
                    label: stats.membersCount == 1 ? 'membre' : 'membres',
                  ),
                  _StatCard(
                    icon: Icons.eco_outlined,
                    value: '${stats.verifiedActionsCount}',
                    label: stats.verifiedActionsCount == 1
                        ? 'action vérifiée'
                        : 'actions vérifiées',
                  ),
                  _StatCard(
                    icon: Icons.star_outline,
                    value: '${stats.totalPoints}',
                    label: "points d'impact",
                  ),
                  _StatCard(
                    icon: Icons.event_outlined,
                    value: '${stats.eventsCount}',
                    label: stats.eventsCount == 1 ? 'campagne' : 'campagnes',
                  ),
                  _StatCard(
                    icon: Icons.apartment_outlined,
                    value: '${stats.organizationsCount}',
                    label: stats.organizationsCount == 1 ? 'organisation' : 'organisations',
                  ),
                ],
              ),
              if (stats.quantityTotals.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Par type de quantité', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: stats.quantityTotals.entries.map((entry) {
                    final value = entry.value == entry.value.roundToDouble()
                        ? entry.value.toInt().toString()
                        : entry.value.toString();
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text('$value ${entry.key}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
