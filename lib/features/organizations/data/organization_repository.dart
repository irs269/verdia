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

  /// Organisations dont [profileId] est membre (propriétaire ou non) — sert
  /// au sélecteur "Publier en tant que" lors de la création d'un
  /// événement/défi (voir audit, item "Création de campagnes par une
  /// organisation").
  Future<List<Organization>> fetchMyOrganizations(String profileId) async {
    try {
      final data = await _client
          .from('organization_members')
          .select('organizations(*)')
          .eq('profile_id', profileId);
      return (data as List)
          .map((e) => Organization.fromMap((e as Map<String, dynamic>)['organizations']
              as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
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

  /// Toujours créée non vérifiée (`verified` garde son défaut `false` — le
  /// trigger `prevent_owner_self_verification`, migration 0016, empêche de
  /// toute façon le créateur de se vérifier lui-même). Le créateur devient
  /// automatiquement `owner`.
  Future<Organization> createOrganization({
    required String creatorId,
    required String name,
    required String description,
    required String category,
    String? city,
    String? country,
    String? website,
  }) async {
    try {
      final data = await _client
          .from('organizations')
          .insert({
            'name': name,
            'description': description,
            'category': category,
            'city': city,
            'country': country,
            'website': website,
          })
          .select()
          .single();
      final organization = Organization.fromMap(data);
      await _client.from('organization_members').insert({
        'organization_id': organization.id,
        'profile_id': creatorId,
        'role': 'owner',
      });
      return organization;
    } catch (_) {
      throw const AppException("La création de l'organisation a échoué.");
    }
  }

  Future<List<OrganizationMember>> fetchMembers(String organizationId) async {
    try {
      final data = await _client
          .from('organization_members')
          .select('profile_id, role, profiles(username, first_name, last_name, avatar_url)')
          .eq('organization_id', organizationId)
          .order('role');
      return (data as List)
          .map((e) => OrganizationMember.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addMember({required String organizationId, required String profileId}) async {
    try {
      await _client.from('organization_members').insert({
        'organization_id': organizationId,
        'profile_id': profileId,
        'role': 'member',
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AppException('Ce membre fait déjà partie de l\'organisation.');
      }
      throw const AppException("L'ajout du membre a échoué.");
    } catch (_) {
      throw const AppException("L'ajout du membre a échoué.");
    }
  }

  Future<void> removeMember({required String organizationId, required String profileId}) async {
    try {
      await _client
          .from('organization_members')
          .delete()
          .eq('organization_id', organizationId)
          .eq('profile_id', profileId);
    } catch (_) {
      throw const AppException('Le retrait du membre a échoué.');
    }
  }

  /// Réservé aux modérateurs (policy "Moderators can update any
  /// organization", migration 0016) — écrit dans le seul champ que le
  /// trigger `prevent_owner_self_verification` laisse un modérateur changer.
  Future<void> setVerified({required String organizationId, required bool verified}) async {
    try {
      await _client.from('organizations').update({'verified': verified}).eq('id', organizationId);
    } catch (_) {
      throw const AppException('La mise à jour du statut a échoué.');
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
