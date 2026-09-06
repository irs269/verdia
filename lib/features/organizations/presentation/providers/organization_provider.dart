import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

final organizationControllerProvider =
    AsyncNotifierProvider.autoDispose<OrganizationController, void>(OrganizationController.new);

class OrganizationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

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
