import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/organization.dart';
import '../providers/organization_provider.dart';

class OrganizationDetailScreen extends ConsumerWidget {
  const OrganizationDetailScreen({super.key, required this.organizationId});

  final String organizationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationAsync = ref.watch(organizationByIdProvider(organizationId));
    final isOwner = ref.watch(isOrganizationOwnerProvider(organizationId)).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (isOwner)
            organizationAsync.maybeWhen(
              data: (org) => IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Modifier',
                onPressed: () => context.push('/organizations/$organizationId/edit', extra: org),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: organizationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (org) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage:
                      org.logoUrl != null ? CachedNetworkImageProvider(org.logoUrl!) : null,
                  child: org.logoUrl == null
                      ? Text(OrganizationCategory.icon(org.category),
                          style: const TextStyle(fontSize: 36))
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        org.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (org.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, size: 20, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '${OrganizationCategory.icon(org.category)} ${OrganizationCategory.label(org.category)}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(org.description, style: Theme.of(context).textTheme.bodyMedium),
              if (org.location != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(org.location!, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
              if (org.website != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(org.website!,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text('Bilan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Consumer(
                builder: (context, ref, _) {
                  final membersAsync = ref.watch(organizationMembersProvider(organizationId));
                  final memberCount = membersAsync.valueOrNull?.length;
                  return Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.groups_outlined,
                          value: memberCount?.toString() ?? '—',
                          label: memberCount == 1 ? 'membre' : 'membres',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.calendar_today_outlined,
                          value: DateFormat('MMM yyyy', 'fr_FR').format(org.createdAt),
                          label: 'depuis',
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (!org.verified) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          "Organisation non vérifiée pour l'instant.",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
