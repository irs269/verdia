import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(SupabaseService.client);
});

/// Le profil de l'utilisateur connecté. `null` si personne n'est connecté.
/// Invalider ce provider après une mise à jour pour refléter les changements.
final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});

/// Le profil public d'un utilisateur quelconque (vue "profil d'un autre membre").
final profileByIdProvider =
    FutureProvider.autoDispose.family<Profile, String>((ref, profileId) {
  return ref.watch(profileRepositoryProvider).getProfile(profileId);
});

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, void>(
  ProfileController.new,
);

class ProfileController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    String? bio,
    String? city,
    String? country,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio,
            city: city,
            country: country,
          );
    });
    if (!state.hasError) ref.invalidate(currentProfileProvider);
    return !state.hasError;
  }

  Future<bool> uploadAvatar(Uint8List bytes) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(userId: userId, bytes: bytes);
    });
    if (!state.hasError) ref.invalidate(currentProfileProvider);
    return !state.hasError;
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(profileRepositoryProvider)
        .setNotificationsEnabled(userId: userId, enabled: enabled));
    if (!state.hasError) ref.invalidate(currentProfileProvider);
    return !state.hasError;
  }

  Future<bool> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(profileRepositoryProvider).deleteAccount());
    return !state.hasError;
  }
}
