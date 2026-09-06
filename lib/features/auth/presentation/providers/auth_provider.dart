import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(SupabaseService.client);
});

/// Émet un nouvel événement à chaque changement de session (login, logout,
/// refresh de token). Sert de source de vérité pour le routeur.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// L'utilisateur courant, dérivé de l'état d'auth ci-dessus.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider).valueOrNull;
  return authState?.session?.user ??
      ref.watch(authRepositoryProvider).currentUser;
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// Encapsule les actions d'auth (login/register/logout/reset) avec un état
/// loading/error exploitable directement par les écrans.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) {
    return _run(() => _repo.signInWithPassword(email: email, password: password));
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
  }) {
    return _run(() => _repo.signUp(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          username: username,
        ));
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _run(() => _repo.sendPasswordResetEmail(email));
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
