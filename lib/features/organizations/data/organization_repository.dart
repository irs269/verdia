import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/organization.dart';

class OrganizationRepository {
  OrganizationRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

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

  /// `true` si [profileId] est `owner` de [organizationId] — détermine si le
  /// bouton "Modifier" est proposé (voir migration 0013/0015). Ne lève
  /// jamais : une erreur réseau se traduit juste par "pas propriétaire".
  Future<bool> isOwner(String organizationId, String profileId) async {
    try {
      final data = await _client
          .from('organization_members')
          .select('role')
          .eq('organization_id', organizationId)
          .eq('profile_id', profileId)
          .maybeSingle();
      return data != null && data['role'] == 'owner';
    } catch (_) {
      return false;
    }
  }

  Future<Organization> updateOrganization({
    required String organizationId,
    required String name,
    required String description,
    String? city,
    String? country,
    String? website,
  }) async {
    try {
      final data = await _client
          .from('organizations')
          .update({
            'name': name,
            'description': description,
            'city': city,
            'country': country,
            'website': website,
          })
          .eq('id', organizationId)
          .select()
          .single();
      return Organization.fromMap(data);
    } catch (_) {
      throw const AppException("La mise à jour de l'organisation a échoué.");
    }
  }

  Future<String> uploadLogo({required String organizationId, required Uint8List bytes}) async {
    final path = '$organizationId/${_uuid.v4()}.jpg';
    try {
      await _client.storage.from('organization-media').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      final url = _client.storage.from('organization-media').getPublicUrl(path);
      await _client.from('organizations').update({'logo_url': url}).eq('id', organizationId);
      return url;
    } catch (_) {
      throw const AppException("L'envoi du logo a échoué.");
    }
  }
}
