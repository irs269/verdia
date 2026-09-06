import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/action_category.dart';
import '../domain/eco_action.dart';

const _actionSelect = '''
  id, author_id, title, description, quantity, quantity_unit, participants_count,
  city, country, lat, lng, occurred_at, status, created_at, location_verified,
  action_categories(id, code, label, icon, color),
  impact_points(points)
''';

const _actionsPageSize = 20;

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
      final data = await query.order('created_at', ascending: false).limit(_actionsPageSize);
      return (data as List)
          .map((e) => EcoAction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les actions.');
    }
  }

  /// Réservé aux modérateurs (RLS "Actions are viewable by everyone" reste
  /// vraie côté lecture, mais seul un modérateur voit ce filtre exploité —
  /// migration 0017) : actions en attente de validation.
  Future<List<EcoAction>> fetchPendingActions() async {
    try {
      final data = await _client
          .from('actions')
          .select(_actionSelect)
          .eq('status', 'pending')
          .order('created_at');
      return (data as List)
          .map((e) => EcoAction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
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
  /// associée et ses médias. Le statut par défaut est 'pending' (migration
  /// 0017) : les points ne sont crédités qu'une fois qu'un modérateur la
  /// fait passer à 'verified' via [moderateAction]. [avantBytes]/[apresBytes]
  /// sont taguées `label` dans
  /// `post_media` (migration 0015) et uploadées avant la galerie générale
  /// pour que leur `position` (0, puis 1) soit stable.
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
    required DateTime occurredAt,
    double? deviceLat,
    double? deviceLng,
    bool locationVerified = false,
    Uint8List? avantBytes,
    Uint8List? apresBytes,
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
            'occurred_at': occurredAt.toIso8601String(),
            'device_lat': deviceLat,
            'device_lng': deviceLng,
            'location_verified': locationVerified,
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

      Future<void> uploadMedia(Uint8List bytes, int position, {String? label}) async {
        final path = '$authorId/${_uuid.v4()}.jpg';
        await _client.storage.from('post-media').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        final url = _client.storage.from('post-media').getPublicUrl(path);
        await _client.from('post_media').insert({
          'post_id': postId,
          'url': url,
          'type': 'image',
          'position': position,
          'label': label,
        });
      }

      var position = 0;
      if (avantBytes != null) await uploadMedia(avantBytes, position++, label: 'avant');
      if (apresBytes != null) await uploadMedia(apresBytes, position++, label: 'apres');
      for (final bytes in mediaBytes) {
        await uploadMedia(bytes, position++);
      }
    } catch (_) {
      throw const AppException("La création de l'action a échoué. Réessaie.");
    }
  }

  /// Réservé aux modérateurs — passe par la fonction RPC `moderate_action`
  /// (migration 0018), seule capable d'écrire `actions.status` : la colonne
  /// est verrouillée pour `authenticated` depuis la migration 0009
  /// (`revoke update (status)`, Phase 8), y compris pour un modérateur, ce
  /// rôle n'existant qu'au niveau applicatif et non comme rôle Postgres
  /// séparé — un simple `.update()` échoue toujours avec 42501. Le trigger
  /// `revoke_action_points` retire automatiquement les points déjà crédités
  /// si le nouveau statut est 'rejected'. `notes` est journalisé dans
  /// `moderation_actions` pour traçabilité.
  Future<void> moderateAction({
    required String actionId,
    required String moderatorId,
    required String status,
    String? notes,
    String? reportId,
  }) async {
    try {
      await _client.rpc('moderate_action', params: {
        'p_action_id': actionId,
        'p_new_status': status,
      });
      if (reportId != null) {
        await _client.from('moderation_actions').insert({
          'report_id': reportId,
          'moderator_id': moderatorId,
          'action': status == 'rejected' ? 'content_removed' : 'no_action',
          'notes': notes,
        });
      }
    } catch (_) {
      throw const AppException('La modération a échoué.');
    }
  }

  /// Somme de `quantity` groupée par unité (kg, arbres, ...) pour les actions
  /// vérifiées d'un utilisateur — contrairement à [fetchUserActionCounts]
  /// (nombre d'actions), ceci reflète la quantité réelle déclarée.
  Future<Map<String, double>> fetchUserQuantityTotals(String profileId) async {
    try {
      final data = await _client
          .from('actions')
          .select('quantity, quantity_unit')
          .eq('author_id', profileId)
          .eq('status', 'verified')
          .not('quantity', 'is', null);
      final totals = <String, double>{};
      for (final row in data as List) {
        final unit = row['quantity_unit'] as String? ?? 'unités';
        final qty = (row['quantity'] as num).toDouble();
        totals[unit] = (totals[unit] ?? 0) + qty;
      }
      return totals;
    } catch (_) {
      return {};
    }
  }
}
