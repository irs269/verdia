import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/eco_badge.dart';

class BadgeRepository {
  BadgeRepository(this._client);

  final SupabaseClient _client;

  /// Tous les badges du système, marqués comme débloqués ou non pour
  /// [profileId] (deux requêtes simples plutôt qu'un embed filtré, pour
  /// rester lisible).
  Future<List<EcoBadge>> fetchBadgesFor(String profileId) async {
    try {
      final badgesData = await _client.from('badges').select().order('name');
      final earnedData = await _client
          .from('user_badges')
          .select('badge_id, earned_at')
          .eq('profile_id', profileId);

      final earnedMap = {
        for (final row in earnedData as List)
          row['badge_id'] as String: DateTime.parse(row['earned_at'] as String),
      };

      return (badgesData as List).map((e) {
        final map = e as Map<String, dynamic>;
        return EcoBadge.fromMap(map, earnedAt: earnedMap[map['id']]);
      }).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les badges.');
    }
  }
}
