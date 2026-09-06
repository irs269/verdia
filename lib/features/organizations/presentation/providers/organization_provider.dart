import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
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
