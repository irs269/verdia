import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Point d'accès unique au client Supabase. Initialisé une fois dans
/// `main.dart` avant `runApp`.
abstract final class SupabaseService {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL / SUPABASE_ANON_KEY manquants. '
        'Copie .env.example vers .env et renseigne tes clés Supabase.',
      );
    }

    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
      httpClient: _SessionAwareHttpClient(http.Client()),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

/// Un onglet resté ouvert (ou une appli en arrière-plan) sur mobile peut voir
/// son token expirer avant que le rafraîchissement automatique du SDK n'ait
/// eu l'occasion de tourner (timers JS suspendus sur un onglet inactif,
/// notamment). Sans ce client, une requête échoue alors avec une
/// `PostgrestException(JWT expired...)` brute affichée directement à
/// l'utilisateur sur l'écran courant. Ici, on détecte ce cas précis et on
/// déconnecte proprement : la redirection vers l'écran de connexion déjà en
/// place (`GoRouterRefreshStream` sur `authStateChanges`) prend le relais.
class _SessionAwareHttpClient extends http.BaseClient {
  _SessionAwareHttpClient(this._inner);

  final http.Client _inner;
  bool _handlingExpiry = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    if ((response.statusCode == 401 || response.statusCode == 403) && !_handlingExpiry) {
      final bytes = await response.stream.toBytes();
      final body = utf8.decode(bytes, allowMalformed: true);
      if (body.contains('PGRST303') || body.toLowerCase().contains('jwt expired')) {
        _handlingExpiry = true;
        // Ne bloque pas la réponse en cours sur la déconnexion elle-même.
        unawaited(
          Supabase.instance.client.auth.signOut().whenComplete(() => _handlingExpiry = false),
        );
      }
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        request: response.request,
      );
    }

    return response;
  }
}
