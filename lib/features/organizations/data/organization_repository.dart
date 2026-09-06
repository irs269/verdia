import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/organization.dart';

class OrganizationRepository {
  OrganizationRepository(this._client);

  final SupabaseClient _client;

  Future<List<Organization>> fetchAll() async {
    try {
      final data = await _client.from('organizations').select().order('name');
      return (data as List)
          .map((e) => Organization.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les organisations.');
    }
  }

  Future<Organization> fetchById(String id) async {
    try {
      final data = await _client.from('organizations').select().eq('id', id).single();
      return Organization.fromMap(data);
    } catch (_) {
      throw const AppException('Impossible de charger cette organisation.');
    }
  }
}
