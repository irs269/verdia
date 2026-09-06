import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/profile.dart';

const _followListPageSize = 20;

class FollowRepository {
  FollowRepository(this._client);

  final SupabaseClient _client;

  /// Amis de [profileId] (abonnement toujours réciproque depuis la migration
  /// 0026 — "follower"/"following" désignent donc la même relation), triés
  /// du plus récent au plus ancien.
  Future<List<({Profile profile, DateTime followedAt})>> fetchFriends({
    required String profileId,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from('follows')
          .select('created_at, profiles!follows_following_id_fkey(*)')
          .eq('follower_id', profileId);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final data =
          await query.order('created_at', ascending: false).limit(_followListPageSize);
      return _mapRows(data as List);
    } catch (_) {
      throw const AppException('Impossible de charger les amis.');
    }
  }

  List<({Profile profile, DateTime followedAt})> _mapRows(List data) {
    return [
      for (final row in data.cast<Map<String, dynamic>>())
        (
          profile: Profile.fromMap(row['profiles'] as Map<String, dynamic>),
          followedAt: DateTime.parse(row['created_at'] as String),
        ),
    ];
  }

  Future<int> getFriendCount(String profileId) {
    return _client.from('follows').count(CountOption.exact).eq('follower_id', profileId);
  }

  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final row = await _client
        .from('follows')
        .select()
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return row != null;
  }

  Future<void> follow({required String followerId, required String followingId}) async {
    try {
      await _client
          .from('follows')
          .insert({'follower_id': followerId, 'following_id': followingId});
    } catch (_) {
      throw const AppException("Impossible de suivre cet utilisateur.");
    }
  }

  Future<void> unfollow({required String followerId, required String followingId}) async {
    try {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    } catch (_) {
      throw const AppException("Impossible de ne plus suivre cet utilisateur.");
    }
  }
}
