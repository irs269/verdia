import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/content_report.dart';

class ModerationRepository {
  ModerationRepository(this._client);

  final SupabaseClient _client;

  Future<void> reportContent({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': reporterId,
        'target_type': targetType.value,
        'target_id': targetId,
        'reason': reason,
        'description': description,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AppException('Tu as déjà signalé ce contenu.');
      }
      throw const AppException('Le signalement a échoué.');
    } catch (_) {
      throw const AppException('Le signalement a échoué.');
    }
  }

  /// Réservé aux modérateurs (policy "Moderators can view all reports",
  /// migration 0015) — renvoie une liste vide pour tout le monde d'autre.
  Future<List<Report>> fetchPendingReports() async {
    try {
      final data = await _client
          .from('reports')
          .select()
          .eq('status', ReportStatus.pending)
          .order('created_at');
      return (data as List).map((e) => Report.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fait évoluer un signalement et journalise la décision. `contentAction`
  /// correspond aux valeurs acceptées par `moderation_actions.action`.
  Future<void> resolveReport({
    required String reportId,
    required String moderatorId,
    required String newStatus,
    required String contentAction,
    String? notes,
  }) async {
    try {
      await _client.from('reports').update({'status': newStatus}).eq('id', reportId);
      await _client.from('moderation_actions').insert({
        'report_id': reportId,
        'moderator_id': moderatorId,
        'action': contentAction,
        'notes': notes,
      });
    } catch (_) {
      throw const AppException('La résolution du signalement a échoué.');
    }
  }
}
