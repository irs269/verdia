import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/profile.dart';

class FollowCounts {
  const FollowCounts({required this.followers, required this.following});
  final int followers;
  final int following;
}

const _followListPageSize = 20;

class FollowRepository {
  FollowRepository(this._client);

  final SupabaseClient _client;

  /// Utilisateurs qui suivent [profileId], triés du plus récent abonné au
  /// plus ancien.
  Future<List<({Profile profile, DateTime followedAt})>> fetchFollowers({
    required String profileId,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from('follows')
          .select('created_at, profiles!follows_follower_id_fkey(*)')
          .eq('following_id', profileId);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final data =
          await query.order('created_at', ascending: false).limit(_followListPageSize);
      return _mapRows(data as List);
    } catch (_) {
      throw const AppException('Impossible de charger les abonnés.');
    }
  }

  /// Utilisateurs que [profileId] suit, triés du plus récemment suivi au
  /// plus ancien.
  Future<List<({Profile profile, DateTime followedAt})>> fetchFollowing({
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
      throw const AppException('Impossible de charger les abonnements.');
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

  Future<FollowCounts> getCounts(String profileId) async {
    final followers = await _client
        .from('follows')
        .count(CountOption.exact)
        .eq('following_id', profileId);
    final following = await _client
        .from('follows')
        .count(CountOption.exact)
        .eq('follower_id', profileId);
    return FollowCounts(followers: followers, following: following);
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
