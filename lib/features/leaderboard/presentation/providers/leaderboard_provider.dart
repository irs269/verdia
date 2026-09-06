import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/leaderboard_repository.dart';
import '../../domain/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(SupabaseService.client);
});

final globalLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).fetchGlobal();
});

/// `null` tant que le profil courant (et donc sa ville) n'est pas chargé.
final cityLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile?.city == null || profile!.city!.isEmpty) return null;
  return ref.watch(leaderboardRepositoryProvider).fetchByCity(profile.city!);
});
