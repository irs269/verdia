import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/organization_repository.dart';
import '../../domain/organization.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(SupabaseService.client);
});

final organizationsListProvider = FutureProvider.autoDispose<List<Organization>>((ref) {
  return ref.read(organizationRepositoryProvider).fetchAll();
});

final organizationByIdProvider =
    FutureProvider.autoDispose.family<Organization, String>((ref, id) {
  return ref.read(organizationRepositoryProvider).fetchById(id);
});

/// `false` tant que personne n'est connecté ou que le profil courant n'est
/// pas `owner` de cette organisation.
final isOrganizationOwnerProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, organizationId) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return false;
  return ref.watch(organizationRepositoryProvider).isOwner(organizationId, userId);
});

final organizationMembersProvider =
    FutureProvider.autoDispose.family<List<OrganizationMember>, String>((ref, organizationId) {
  return ref.watch(organizationRepositoryProvider).fetchMembers(organizationId);
});

/// Organisations en attente de vérification — réservé aux modérateurs par
/// l'écran appelant (la lecture elle-même reste publique, voir migration
/// 0013 : "Organizations are viewable by everyone").
final unverifiedOrganizationsProvider = FutureProvider.autoDispose<List<Organization>>((ref) async {
  final all = await ref.watch(organizationsListProvider.future);
  return all.where((o) => !o.verified).toList();
});

final organizationControllerProvider =
    AsyncNotifierProvider.autoDispose<OrganizationController, void>(OrganizationController.new);

class OrganizationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Organization?> create({
    required String name,
    required String description,
    required String category,
    String? city,
    String? country,
    String? website,
  }) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return null;

    Organization? created;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      created = await ref.read(organizationRepositoryProvider).createOrganization(
            creatorId: userId,
            name: name,
            description: description,
            category: category,
            city: city,
            country: country,
            website: website,
          );
    });
    if (!state.hasError) ref.invalidate(organizationsListProvider);
    return state.hasError ? null : created;
  }

  Future<bool> addMember({required String organizationId, required String username}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final matches =
          await ref.read(profileRepositoryProvider).searchProfiles(username);
      final exact = matches.where((p) => p.username == username).toList();
      if (exact.isEmpty) throw const AppException('Aucun utilisateur avec ce nom.');
      await ref.read(organizationRepositoryProvider).addMember(
            organizationId: organizationId,
            profileId: exact.first.id,
          );
    });
    if (!state.hasError) ref.invalidate(organizationMembersProvider(organizationId));
    return !state.hasError;
  }

  Future<bool> removeMember({required String organizationId, required String profileId}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(organizationRepositoryProvider)
        .removeMember(organizationId: organizationId, profileId: profileId));
    if (!state.hasError) ref.invalidate(organizationMembersProvider(organizationId));
    return !state.hasError;
  }

  Future<bool> setVerified({required String organizationId, required bool verified}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref
        .read(organizationRepositoryProvider)
        .setVerified(organizationId: organizationId, verified: verified));
    if (!state.hasError) {
      ref.invalidate(organizationsListProvider);
      ref.invalidate(unverifiedOrganizationsProvider);
      ref.invalidate(organizationByIdProvider(organizationId));
    }
    return !state.hasError;
  }

  Future<bool> updateOrganization({
    required String organizationId,
    required String name,
    required String description,
    String? city,
    String? country,
    String? website,
    Uint8List? newLogoBytes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.updateOrganization(
        organizationId: organizationId,
        name: name,
        description: description,
        city: city,
        country: country,
        website: website,
      );
      if (newLogoBytes != null) {
        await repo.uploadLogo(organizationId: organizationId, bytes: newLogoBytes);
      }
    });
    if (!state.hasError) {
      ref.invalidate(organizationByIdProvider(organizationId));
      ref.invalidate(organizationsListProvider);
    }
    return !state.hasError;
  }
}
