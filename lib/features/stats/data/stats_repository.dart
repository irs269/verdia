import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/community_stats.dart';

/// Vue d'impact cumulé de toute la communauté VERDIA — voir audit, item
/// "Statistiques globales de VERDIA". Les agrégations (somme des points,
/// des quantités) se font côté client sur les colonnes brutes, comme
/// `ActionRepository.fetchUserQuantityTotals` : PostgREST n'expose pas de
/// SUM() sans vue/fonction dédiée, et le volume de lignes reste minime à
/// l'échelle de ce projet.
class StatsRepository {
  StatsRepository(this._client);

  final SupabaseClient _client;

  Future<CommunityStats> fetchCommunityStats() async {
    try {
      final results = await Future.wait([
        _client.from('profiles').count(CountOption.exact),
        _client.from('actions').count(CountOption.exact).eq('status', 'verified'),
        _client.from('events').count(CountOption.exact),
        _client.from('organizations').count(CountOption.exact),
        _client.from('profiles').select('total_points'),
        _client
            .from('actions')
            .select('quantity, quantity_unit')
            .eq('status', 'verified')
            .not('quantity', 'is', null),
      ]);

      final membersCount = results[0] as int;
      final verifiedActionsCount = results[1] as int;
      final eventsCount = results[2] as int;
      final organizationsCount = results[3] as int;

      final pointsRows = results[4] as List;
      final totalPoints = pointsRows.fold<int>(
        0,
        (sum, row) => sum + ((row as Map<String, dynamic>)['total_points'] as int? ?? 0),
      );

      final quantityRows = results[5] as List;
      final quantityTotals = <String, double>{};
      for (final row in quantityRows) {
        final map = row as Map<String, dynamic>;
        final unit = map['quantity_unit'] as String? ?? 'unités';
        final qty = (map['quantity'] as num).toDouble();
        quantityTotals[unit] = (quantityTotals[unit] ?? 0) + qty;
      }

      return CommunityStats(
        membersCount: membersCount,
        verifiedActionsCount: verifiedActionsCount,
        totalPoints: totalPoints,
        eventsCount: eventsCount,
        organizationsCount: organizationsCount,
        quantityTotals: quantityTotals,
      );
    } catch (_) {
      throw const AppException('Impossible de charger les statistiques.');
    }
  }
}
