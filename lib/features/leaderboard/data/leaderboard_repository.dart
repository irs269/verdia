import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/leaderboard_entry.dart';

const _select = 'id, username, first_name, last_name, avatar_url, total_points';

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;

  Future<List<LeaderboardEntry>> fetchGlobal({int limit = 50}) async {
    try {
      final data = await _client
          .from('profiles')
          .select(_select)
          .order('total_points', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger le classement.');
    }
  }

  Future<List<LeaderboardEntry>> fetchByCity(String city, {int limit = 50}) async {
    try {
      final data = await _client
          .from('profiles')
          .select(_select)
          .eq('city', city)
          .order('total_points', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger le classement.');
    }
  }
}
