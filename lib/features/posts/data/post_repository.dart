import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/search.dart';
import '../domain/comment.dart';
import '../domain/post.dart';

enum FeedType { forYou, following }

const _feedPageSize = 10;
const _userPostsPageSize = 10;
const _commentsPageSize = 20;
const _savedPostsPageSize = 10;
const _postSelect = '''
  id, author_id, content, city, country, created_at,
  profiles!posts_author_id_fkey(username, first_name, last_name, avatar_url),
  post_media(id, url, type, position, label),
  likes(count),
  comments(count),
  actions(
    id, title, description, quantity, quantity_unit, participants_count,
    city, country, occurred_at, status, created_at, location_verified,
    action_categories(id, code, label, icon, color),
    impact_points(points)
  )
''';

class PostRepository {
  PostRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<List<Post>> fetchFeed({
    required FeedType type,
    DateTime? before,
    String? currentUserId,
  }) async {
    try {
      var query = _client.from('posts').select(_postSelect);

      if (type == FeedType.following) {
        if (currentUserId == null) return [];
        final following = await _client
            .from('follows')
            .select('following_id')
            .eq('follower_id', currentUserId);
        final ids = (following as List)
            .map((e) => e['following_id'] as String)
            .toList();
        if (ids.isEmpty) return [];
        query = query.inFilter('author_id', ids);
      }

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(_feedPageSize);

      final posts = (data as List)
          .map((e) => Post.fromMap(e as Map<String, dynamic>))
          .toList();

      if (currentUserId == null || posts.isEmpty) return posts;
      return _attachViewerState(posts, currentUserId);
    } catch (_) {
      throw const AppException('Impossible de charger le fil.');
    }
  }

  Future<List<Post>> _attachViewerState(
    List<Post> posts,
    String currentUserId,
  ) async {
    final postIds = posts.map((p) => p.id).toList();
    final likedRows = await _client
        .from('likes')
        .select('post_id')
        .eq('profile_id', currentUserId)
        .inFilter('post_id', postIds);
    final savedRows = await _client
        .from('saved_posts')
        .select('post_id')
        .eq('profile_id', currentUserId)
        .inFilter('post_id', postIds);

    final likedIds = (likedRows as List).map((e) => e['post_id'] as String).toSet();
    final savedIds = (savedRows as List).map((e) => e['post_id'] as String).toSet();

    return posts
        .map((p) => p.copyWith(
              isLikedByMe: likedIds.contains(p.id),
              isSavedByMe: savedIds.contains(p.id),
            ))
        .toList();
  }

  Future<List<Post>> fetchUserPosts({
    required String authorId,
    String? currentUserId,
    DateTime? before,
  }) async {
    try {
      var query = _client.from('posts').select(_postSelect).eq('author_id', authorId);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(_userPostsPageSize);

      final posts = (data as List)
          .map((e) => Post.fromMap(e as Map<String, dynamic>))
          .toList();

      if (currentUserId == null || posts.isEmpty) return posts;
      return _attachViewerState(posts, currentUserId);
    } catch (_) {
      throw const AppException('Impossible de charger les publications.');
    }
  }

  /// Le tri se fait par date d'enregistrement (pas par date de publication du
  /// post) — c'est le comportement attendu d'une liste de favoris.
  Future<List<({Post post, DateTime savedAt})>> fetchSavedPosts({
    required String userId,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from('saved_posts')
          .select('created_at, posts($_postSelect)')
          .eq('profile_id', userId);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final data =
          await query.order('created_at', ascending: false).limit(_savedPostsPageSize);
      final rows = (data as List).cast<Map<String, dynamic>>();
      if (rows.isEmpty) return [];

      final posts =
          rows.map((e) => Post.fromMap(e['posts'] as Map<String, dynamic>)).toList();
      final withViewerState = await _attachViewerState(posts, userId);

      return [
        for (var i = 0; i < rows.length; i++)
          (
            post: withViewerState[i],
            savedAt: DateTime.parse(rows[i]['created_at'] as String),
          ),
      ];
    } catch (_) {
      throw const AppException('Impossible de charger les publications enregistrées.');
    }
  }

  Future<List<Post>> searchPosts(String query, {String? currentUserId}) async {
    try {
      final term = sanitizeSearchTerm(query);
      final data = await _client
          .from('posts')
          .select(_postSelect)
          .ilike('content', '%$term%')
          .order('created_at', ascending: false)
          .limit(20);

      final posts = (data as List)
          .map((e) => Post.fromMap(e as Map<String, dynamic>))
          .toList();

      if (currentUserId == null || posts.isEmpty) return posts;
      return _attachViewerState(posts, currentUserId);
    } catch (_) {
      throw const AppException('Impossible de rechercher les publications.');
    }
  }

  /// `post_media`/`likes`/`comments`/`saved_posts` partent en cascade (voir
  /// les FKs de la migration 0003) ; les fichiers du bucket `post-media` ne
  /// sont eux jamais nettoyés automatiquement, limitation connue et acceptée
  /// pour ce MVP.
  Future<void> deletePost(String postId) async {
    try {
      await _client.from('posts').delete().eq('id', postId);
    } catch (_) {
      throw const AppException('La suppression a échoué.');
    }
  }

  Future<void> updatePost(String postId, String content) async {
    try {
      await _client.from('posts').update({'content': content}).eq('id', postId);
    } catch (_) {
      throw const AppException('La modification a échoué.');
    }
  }

  /// Compteurs de likes/commentaires en direct, tous posts confondus (migration
  /// 0014). Les payloads Realtime de Supabase ne contiennent jamais de jointure
  /// (`profiles`, ...), seulement les colonnes brutes de la table — inutile
  /// pour reconstruire un [Post]/[Comment] complet, mais suffisant pour
  /// recompter par `post_id` et mettre à jour les compteurs déjà affichés.
  Stream<Map<String, int>> streamLikeCounts() {
    return _client.from('likes').stream(primaryKey: ['id']).map(_countByPostId);
  }

  Stream<Map<String, int>> streamCommentCounts() {
    return _client.from('comments').stream(primaryKey: ['id']).map(_countByPostId);
  }

  Map<String, int> _countByPostId(List<Map<String, dynamic>> rows) {
    final counts = <String, int>{};
    for (final row in rows) {
      final postId = row['post_id'] as String;
      counts[postId] = (counts[postId] ?? 0) + 1;
    }
    return counts;
  }

  /// Signal Realtime "quelque chose a changé" pour les commentaires d'un post
  /// donné : le payload n'ayant pas la jointure `profiles` nécessaire à
  /// [Comment.fromMap], on l'utilise juste pour déclencher un rafraîchissement
  /// via [fetchComments] (qui, lui, a la jointure complète).
  Stream<void> streamCommentsChanged(String postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((_) {});
  }

  Future<void> createPost({
    required String authorId,
    required String content,
    String? city,
    String? country,
    required List<Uint8List> mediaBytes,
  }) async {
    try {
      final post = await _client
          .from('posts')
          .insert({
            'author_id': authorId,
            'content': content,
            'city': city,
            'country': country,
          })
          .select('id')
          .single();
      final postId = post['id'] as String;

      for (var i = 0; i < mediaBytes.length; i++) {
        final path = '$authorId/${_uuid.v4()}.jpg';
        await _client.storage.from('post-media').uploadBinary(
              path,
              mediaBytes[i],
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        final url = _client.storage.from('post-media').getPublicUrl(path);
        await _client.from('post_media').insert({
          'post_id': postId,
          'url': url,
          'type': 'image',
          'position': i,
        });
      }
    } catch (_) {
      throw const AppException('La publication a échoué. Réessaie.');
    }
  }

  Future<void> like(String postId, String profileId) async {
    try {
      await _client.from('likes').insert({'post_id': postId, 'profile_id': profileId});
    } catch (_) {
      throw const AppException("Impossible d'aimer cette publication.");
    }
  }

  Future<void> unlike(String postId, String profileId) async {
    try {
      await _client
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('profile_id', profileId);
    } catch (_) {
      throw const AppException("Impossible de retirer le like.");
    }
  }

  Future<void> save(String postId, String profileId) async {
    try {
      await _client
          .from('saved_posts')
          .insert({'post_id': postId, 'profile_id': profileId});
    } catch (_) {
      throw const AppException("Impossible d'enregistrer cette publication.");
    }
  }

  Future<void> unsave(String postId, String profileId) async {
    try {
      await _client
          .from('saved_posts')
          .delete()
          .eq('post_id', postId)
          .eq('profile_id', profileId);
    } catch (_) {
      throw const AppException("Impossible de retirer l'enregistrement.");
    }
  }

  Future<List<Comment>> fetchComments(String postId, {DateTime? after}) async {
    try {
      var query = _client
          .from('comments')
          .select(
            'id, post_id, author_id, content, created_at, profiles!comments_author_id_fkey(username, first_name, last_name, avatar_url)',
          )
          .eq('post_id', postId);

      if (after != null) {
        query = query.gt('created_at', after.toIso8601String());
      }

      final data = await query.order('created_at').limit(_commentsPageSize);
      return (data as List)
          .map((e) => Comment.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les commentaires.');
    }
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    try {
      await _client.from('comments').insert({
        'post_id': postId,
        'author_id': authorId,
        'content': content,
      });
    } catch (_) {
      throw const AppException("L'envoi du commentaire a échoué.");
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('comments').delete().eq('id', commentId);
    } catch (_) {
      throw const AppException('La suppression a échoué.');
    }
  }
}
