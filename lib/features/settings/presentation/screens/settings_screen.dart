import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Voir audit, item "Paramètres" : langue, notifications, suppression de
/// compte. Une seule langue (français) est disponible pour l'instant —
/// l'architecture i18n (Phase 13) est prête mais aucune deuxième langue n'a
/// été traduite, donc le sélecteur reste informatif.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ton compte ?'),
        content: const Text(
          'Toutes tes actions, publications, commentaires et données seront '
          'définitivement supprimés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer définitivement',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(profileControllerProvider.notifier).deleteAccount();
    if (!context.mounted) return;
    if (success) {
      await ref.read(authControllerProvider.notifier).signOut();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('La suppression du compte a échoué.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final controllerState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (profile) => ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Text('GÉNÉRAL',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            const ListTile(
              leading: Icon(Icons.language_outlined),
              title: Text('Langue'),
              subtitle: Text('Français (seule langue disponible pour l\'instant)'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              subtitle: const Text(
                  "Recevoir une notification pour les likes, commentaires, abonnements..."),
              value: profile?.notificationsEnabled ?? true,
              onChanged: controllerState.isLoading
                  ? null
                  : (value) =>
                      ref.read(profileControllerProvider.notifier).setNotificationsEnabled(value),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Text('COMPTE',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer mon compte',
                  style: TextStyle(color: AppColors.error)),
              onTap: controllerState.isLoading ? null : () => _confirmDeleteAccount(context, ref),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Se déconnecter'),
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
