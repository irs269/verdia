import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/environmental_report.dart';

class ReportRepository {
  ReportRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<List<EnvironmentalReport>> fetchReports() async {
    try {
      final data = await _client
          .from('environmental_reports')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List)
          .map((e) => EnvironmentalReport.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les signalements.');
    }
  }

  Future<void> createReport({
    required String authorId,
    required String type,
    required String description,
    required double lat,
    required double lng,
    String? city,
    String? country,
    Uint8List? photoBytes,
  }) async {
    try {
      String? photoUrl;
      if (photoBytes != null) {
        final path = '$authorId/${_uuid.v4()}.jpg';
        await _client.storage.from('report-media').uploadBinary(
              path,
              photoBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        photoUrl = _client.storage.from('report-media').getPublicUrl(path);
      }

      await _client.from('environmental_reports').insert({
        'author_id': authorId,
        'type': type,
        'description': description,
        'photo_url': photoUrl,
        'lat': lat,
        'lng': lng,
        'city': city,
        'country': country,
      });
    } catch (_) {
      throw const AppException('Le signalement a échoué. Réessaie.');
    }
  }
}
