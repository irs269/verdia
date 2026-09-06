import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../features/profile/domain/profile.dart';

/// Ligne "avatar + nom + @username" cliquable vers le profil, réutilisée par
/// toute liste d'utilisateurs (abonnés/abonnements, résultats de recherche).
class ProfileListTile extends StatelessWidget {
  const ProfileListTile({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/users/${profile.id}'),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: profile.avatarUrl != null
            ? CachedNetworkImageProvider(profile.avatarUrl!)
            : null,
        child: profile.avatarUrl == null
            ? const Icon(Icons.person, color: AppColors.textSecondary)
            : null,
      ),
      title: Text(profile.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('@${profile.username}'),
    );
  }
}
