import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/events/domain/event.dart';

Map<String, dynamic> _eventMap({
  String? city,
  String? country,
  List<Map<String, dynamic>>? participants,
  int? targetParticipants,
}) {
  return {
    'id': 'event-1',
    'organizer_id': 'organizer-1',
    'title': 'Nettoyage de la plage de Moroni',
    'description': 'Grand nettoyage communautaire',
    'cover_url': null,
    'lat': -11.7042,
    'lng': 43.2402,
    'city': city,
    'country': country,
    'starts_at': '2026-09-12T08:00:00.000Z',
    'ends_at': null,
    'target_participants': targetParticipants,
    'status': 'upcoming',
    'profiles': {
      'username': 'ahmed.verdia',
      'first_name': 'Ahmed',
      'last_name': 'Said',
      'avatar_url': null,
    },
    'event_participants': participants ?? [],
  };
}

void main() {
  group('Event.fromMap', () {
    test('parses organizer, coordinates and schedule', () {
      final event = Event.fromMap(_eventMap());
      expect(event.organizer.fullName, 'Ahmed Said');
      expect(event.lat, -11.7042);
      expect(event.lng, 43.2402);
      expect(event.startsAt, DateTime.parse('2026-09-12T08:00:00.000Z'));
      expect(event.endsAt, isNull);
    });

    test('counts participants and detects membership', () {
      final event = Event.fromMap(
        _eventMap(participants: [
          {'profile_id': 'organizer-1'},
          {'profile_id': 'me'},
        ]),
        currentUserId: 'me',
      );
      expect(event.participantsCount, 2);
      expect(event.isJoinedByMe, isTrue);
    });

    test('isJoinedByMe is false for a non-participant', () {
      final event = Event.fromMap(
        _eventMap(participants: [
          {'profile_id': 'organizer-1'}
        ]),
        currentUserId: 'someone-else',
      );
      expect(event.isJoinedByMe, isFalse);
    });
  });

  group('Event.location', () {
    test('is null with no city and no country', () {
      expect(Event.fromMap(_eventMap()).location, isNull);
    });

    test('joins city and country', () {
      final event = Event.fromMap(_eventMap(city: 'Moroni', country: 'Comores'));
      expect(event.location, 'Moroni, Comores');
    });
  });

  group('Event.progress', () {
    test('is null when no target has been set', () {
      final event = Event.fromMap(_eventMap());
      expect(event.progress, isNull);
    });

    test('is a fraction between 0 and 1 mid-way', () {
      final event = Event.fromMap(_eventMap(
        targetParticipants: 10,
        participants: List.generate(4, (i) => {'profile_id': 'p$i'}),
      ));
      expect(event.progress, 0.4);
    });

    test('clamps at 1 even if participants exceed the target', () {
      final event = Event.fromMap(_eventMap(
        targetParticipants: 2,
        participants: List.generate(5, (i) => {'profile_id': 'p$i'}),
      ));
      expect(event.progress, 1);
    });
  });
}
