import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/action_category.dart';
import '../domain/eco_action.dart';

const _actionSelect = '''
  id, title, description, quantity, quantity_unit, participants_count,
  city, country, lat, lng, occurred_at, status,
  action_categories(id, code, label, icon, color),
  impact_points(points)
''';

class ActionRepository {
  ActionRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<List<ActionCategory>> fetchCategories() async {
    try {
      final data = await _client.from('action_categories').select().order('label');
      return (data as List)
          .map((e) => ActionCategory.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les catégories.');
    }
  }

  /// Estimation affichée à l'utilisateur avant publication. Les points
  /// réellement crédités sont toujours recalculés et appliqués côté serveur
  /// par le trigger `award_action_points` — jamais par cette valeur.
  Future<int> estimatePoints({required String categoryId, double? quantity}) async {
    try {
      final rule = await _client
          .from('impact_rules')
          .select('points, quantity_multiplier')
          .eq('category_id', categoryId)
          .eq('active', true)
          .maybeSingle();
      if (rule == null) return 0;
      final base = rule['points'] as int;
      final multiplier = (rule['quantity_multiplier'] as num).toDouble();
      return base + ((quantity ?? 0) * multiplier).floor();
    } catch (_) {
      return 0;
    }
  }

  Future<List<EcoAction>> fetchActions({DateTime? before}) async {
    try {
      var query = _client.from('actions').select(_actionSelect).eq('status', 'verified');
      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      final data = await query.order('created_at', ascending: false).limit(20);
      return (data as List)
          .map((e) => EcoAction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les actions.');
    }
  }

  /// Nombre d'actions vérifiées par catégorie pour un utilisateur — utilisé
  /// pour le résumé d'impact du profil.
  Future<Map<String, int>> fetchUserActionCounts(String profileId) async {
    try {
      final data = await _client
          .from('actions')
          .select('action_categories(code)')
          .eq('author_id', profileId)
          .eq('status', 'verified');
      final counts = <String, int>{};
      for (final row in data as List) {
        final code = (row['action_categories'] as Map<String, dynamic>)['code'] as String;
        counts[code] = (counts[code] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  /// Crée l'action, l'auteur comme premier participant, la publication
  /// associée et ses médias. Le statut est 'verified' par défaut pour ce
  /// MVP (validation simple) — le trigger serveur attribue les points.
  Future<void> createAction({
    required String authorId,
    required String categoryId,
    required String title,
    required String description,
    double? quantity,
    String? quantityUnit,
    required int participantsCount,
    String? city,
    String? country,
    double? lat,
    double? lng,
    required List<Uint8List> mediaBytes,
  }) async {
    try {
      final action = await _client
          .from('actions')
          .insert({
            'author_id': authorId,
            'category_id': categoryId,
            'title': title,
            'description': description,
            'quantity': quantity,
            'quantity_unit': quantityUnit,
            'participants_count': participantsCount,
            'city': city,
            'country': country,
            'lat': lat,
            'lng': lng,
          })
          .select('id')
          .single();
      final actionId = action['id'] as String;

      await _client
          .from('action_participants')
          .insert({'action_id': actionId, 'profile_id': authorId});

      final post = await _client
          .from('posts')
          .insert({
            'author_id': authorId,
            'action_id': actionId,
            'content': '$title\n\n$description',
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
      throw const AppException("La création de l'action a échoué. Réessaie.");
    }
  }
}
