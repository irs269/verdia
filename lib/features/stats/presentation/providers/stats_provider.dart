import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/stats_repository.dart';
import '../../domain/community_stats.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(SupabaseService.client);
});

final communityStatsProvider = FutureProvider<CommunityStats>((ref) {
  return ref.watch(statsRepositoryProvider).fetchCommunityStats();
});
