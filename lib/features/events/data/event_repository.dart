import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/search.dart';
import '../domain/event.dart';

const _eventSelect = '''
  id, organizer_id, title, description, cover_url, lat, lng, city, country,
  starts_at, ends_at, target_participants, status,
  profiles!events_organizer_id_fkey(username, first_name, last_name, avatar_url),
  event_participants(profile_id)
''';

class EventRepository {
  EventRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  Future<List<Event>> fetchUpcoming({String? currentUserId}) async {
    try {
      final data = await _client
          .from('events')
          .select(_eventSelect)
          .neq('status', 'cancelled')
          .order('starts_at')
          .limit(30);
      return (data as List)
          .map((e) => Event.fromMap(e as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de charger les événements.');
    }
  }

  Future<List<Event>> searchEvents(String query, {String? currentUserId}) async {
    try {
      final term = sanitizeSearchTerm(query);
      final data = await _client
          .from('events')
          .select(_eventSelect)
          .ilike('title', '%$term%')
          .neq('status', 'cancelled')
          .order('starts_at')
          .limit(20);
      return (data as List)
          .map((e) => Event.fromMap(e as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
    } catch (_) {
      throw const AppException('Impossible de rechercher les événements.');
    }
  }

  Future<Event> createEvent({
    required String organizerId,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? city,
    String? country,
    required DateTime startsAt,
    DateTime? endsAt,
    int? targetParticipants,
    Uint8List? coverBytes,
  }) async {
    try {
      String? coverUrl;
      if (coverBytes != null) {
        final path = '$organizerId/${_uuid.v4()}.jpg';
        await _client.storage.from('event-media').uploadBinary(
              path,
              coverBytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        coverUrl = _client.storage.from('event-media').getPublicUrl(path);
      }

      final data = await _client
          .from('events')
          .insert({
            'organizer_id': organizerId,
            'title': title,
            'description': description,
            'cover_url': coverUrl,
            'lat': lat,
            'lng': lng,
            'city': city,
            'country': country,
            'starts_at': startsAt.toIso8601String(),
            'ends_at': endsAt?.toIso8601String(),
            'target_participants': targetParticipants,
          })
          .select('id')
          .single();
      final eventId = data['id'] as String;

      await _client
          .from('event_participants')
          .insert({'event_id': eventId, 'profile_id': organizerId});

      final full =
          await _client.from('events').select(_eventSelect).eq('id', eventId).single();
      return Event.fromMap(full, currentUserId: organizerId);
    } catch (_) {
      throw const AppException("La création de l'événement a échoué.");
    }
  }

  Future<void> join(String eventId, String profileId) async {
    try {
      await _client
          .from('event_participants')
          .insert({'event_id': eventId, 'profile_id': profileId});
    } catch (_) {
      throw const AppException("Impossible de rejoindre l'événement.");
    }
  }

  Future<void> leave(String eventId, String profileId) async {
    try {
      await _client
          .from('event_participants')
          .delete()
          .eq('event_id', eventId)
          .eq('profile_id', profileId);
    } catch (_) {
      throw const AppException("Impossible de quitter l'événement.");
    }
  }
}
