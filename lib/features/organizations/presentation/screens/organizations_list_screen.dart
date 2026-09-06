import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/organization.dart';
import '../providers/organization_provider.dart';

class OrganizationsListScreen extends ConsumerWidget {
  const OrganizationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationsAsync = ref.watch(organizationsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Organisations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/organizations/create'),
        tooltip: 'Créer une organisation',
        child: const Icon(Icons.add),
      ),
      body: organizationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (organizations) {
          if (organizations.isEmpty) {
            return const Center(
              child: Text('Aucune organisation pour le moment.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: organizations.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final org = organizations[index];
              return ListTile(
                onTap: () => context.push('/organizations/${org.id}'),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceMuted,
                  backgroundImage:
                      org.logoUrl != null ? CachedNetworkImageProvider(org.logoUrl!) : null,
                  child: org.logoUrl == null
                      ? Text(OrganizationCategory.icon(org.category),
                          style: const TextStyle(fontSize: 18))
                      : null,
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(org.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (org.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                subtitle: Text(
                  [OrganizationCategory.label(org.category), if (org.location != null) org.location!]
                      .join(' · '),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
