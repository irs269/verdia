import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/search.dart';
import '../domain/challenge.dart';

const _challengeSelect = '''
  id, title, description, target_value, current_value, unit, ends_at,
  action_categories(id, code, label, icon, color),
  challenge_participants(profile_id)
''';

class ChallengeRepository {
  ChallengeRepository(this._client);

  final SupabaseClient _client;

  Future<List<Challenge>> fetchActive({String? currentUserId}) async {
    try {
      final data = await _client
          .from('challenges')
          .select(_challengeSelect)
          .gt('ends_at', DateTime.now().toIso8601String())
          .order('ends_at');
      return (data as List)
          .map((e) => Challenge.fromMap(e as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les défis.');
    }
  }

  Future<List<Challenge>> searchChallenges(String query, {String? currentUserId}) async {
    try {
      final term = sanitizeSearchTerm(query);
      final data = await _client
          .from('challenges')
          .select(_challengeSelect)
          .ilike('title', '%$term%')
          .order('ends_at')
          .limit(20);
      return (data as List)
          .map((e) => Challenge.fromMap(e as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de rechercher les défis.');
    }
  }

  Future<void> createChallenge({
    required String organizerId,
    required String categoryId,
    required String title,
    required String description,
    required double targetValue,
    required String unit,
    required DateTime endsAt,
  }) async {
    try {
      final challenge = await _client
          .from('challenges')
          .insert({
            'organizer_id': organizerId,
            'category_id': categoryId,
            'title': title,
            'description': description,
            'target_value': targetValue,
            'unit': unit,
            'ends_at': endsAt.toIso8601String(),
          })
          .select('id')
          .single();

      await _client.from('challenge_participants').insert({
        'challenge_id': challenge['id'],
        'profile_id': organizerId,
      });
    } catch (_) {
      throw const AppException('La création du défi a échoué.');
    }
  }

  Future<void> join(String challengeId, String profileId) async {
    try {
      await _client
          .from('challenge_participants')
          .insert({'challenge_id': challengeId, 'profile_id': profileId});
    } catch (_) {
      throw const AppException('Impossible de rejoindre ce défi.');
    }
  }

  Future<void> leave(String challengeId, String profileId) async {
    try {
      await _client
          .from('challenge_participants')
          .delete()
          .eq('challenge_id', challengeId)
          .eq('profile_id', profileId);
    } catch (_) {
      throw const AppException('Impossible de quitter ce défi.');
    }
  }
}
