import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/badge_repository.dart';
import '../../domain/eco_badge.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository(SupabaseService.client);
});

final userBadgesProvider =
    FutureProvider.autoDispose.family<List<EcoBadge>, String>((ref, profileId) {
  return ref.watch(badgeRepositoryProvider).fetchBadgesFor(profileId);
});
