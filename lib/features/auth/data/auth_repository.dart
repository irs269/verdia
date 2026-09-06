import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

/// Accès aux opérations d'authentification Supabase.
///
/// Ne contient aucune logique d'UI : convertit uniquement les erreurs
/// Supabase (auth ou réseau) en [AppException] compréhensibles par les écrans.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _guard(() => _client.auth
        .signInWithPassword(email: email, password: password));
  }

  /// Crée le compte auth. La ligne `profiles` correspondante est créée
  /// automatiquement côté base par le trigger `handle_new_user`
  /// (voir supabase/migrations) à partir des métadonnées passées ici.
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) {
    return _guard(() => _client.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': firstName,
            'last_name': lastName,
            'username': username,
          },
        ));
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _guard(() => _client.auth.resetPasswordForEmail(email));
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Exécute [action] et convertit toute erreur (auth Supabase, réseau,
  /// timeout...) en [AppException] avec un message affichable en français.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthRetryableFetchException {
      // Échec réseau (DNS, offline, timeout...) : GoTrue le remonte comme un
      // AuthException dont le message est le message technique brut de la
      // requête HTTP — jamais affichable tel quel.
      throw const AppException(
        'Connexion impossible. Vérifie ta connexion internet et réessaie.',
        code: 'network_error',
      );
    } on AuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    } catch (_) {
      throw const AppException(
        'Connexion impossible. Vérifie ta connexion internet et réessaie.',
        code: 'network_error',
      );
    }
  }

  String _mapAuthError(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Email ou mot de passe incorrect.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Un compte existe déjà avec cet email.';
      case 'weak_password':
        return 'Mot de passe trop faible (8 caractères minimum).';
      case 'over_email_send_rate_limit':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      default:
        return e.code == null
            ? 'Une erreur est survenue. Réessaie dans quelques instants.'
            : e.message;
    }
  }
}
