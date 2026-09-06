import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/search.dart';
import '../domain/hashtag.dart';

class HashtagRepository {
  HashtagRepository(this._client);

  final SupabaseClient _client;

  Future<List<Hashtag>> searchHashtags(String query) async {
    try {
      final term = sanitizeSearchTerm(query).replaceAll('#', '');
      final data = await _client
          .from('hashtags')
          .select('tag, post_hashtags(count)')
          .ilike('tag', '%$term%')
          .limit(20);
      return (data as List).map((e) => Hashtag.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      throw const AppException('Impossible de rechercher les hashtags.');
    }
  }
}
