import 'package:flutter_dotenv/flutter_dotenv.dart';
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

    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
