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
}
