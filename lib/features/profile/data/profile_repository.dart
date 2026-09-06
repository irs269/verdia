import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/search.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile> getProfile(String userId) async {
    try {
      final data =
          await _client.from('profiles').select().eq('id', userId).single();
      return Profile.fromMap(data);
    } catch (_) {
      throw const AppException('Impossible de charger le profil.');
    }
  }

  Future<List<Profile>> searchProfiles(String query) async {
    try {
      final term = sanitizeSearchTerm(query);
      final data = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%$term%,first_name.ilike.%$term%,last_name.ilike.%$term%')
          .limit(20);
      return (data as List).map((e) => Profile.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const AppException('Impossible de rechercher les utilisateurs.');
    }
  }

  Future<Profile> updateProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String username,
    String? bio,
    String? city,
    String? country,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'username': username,
            'bio': bio,
            'city': city,
            'country': country,
          })
          .eq('id', userId)
          .select()
          .single();
      return Profile.fromMap(data);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AppException("Ce nom d'utilisateur est déjà pris.");
      }
      throw AppException(e.message);
    } catch (_) {
      throw const AppException('La mise à jour du profil a échoué.');
    }
  }

  /// Compresse côté client via `imageQuality` avant l'appel — voir
  /// [EditProfileScreen]. Écrase toujours le même chemin pour éviter
  /// d'accumuler des fichiers orphelins dans le bucket.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
  }) async {
    final path = '$userId/avatar.jpg';
    try {
      await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      // Force le rechargement de l'image (le chemin ne change pas à l'upsert).
      final bustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      await _client
          .from('profiles')
          .update({'avatar_url': bustedUrl}).eq('id', userId);
      return bustedUrl;
    } catch (_) {
      throw const AppException("L'envoi de la photo a échoué.");
    }
  }
}
