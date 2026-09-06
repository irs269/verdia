import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/challenges/domain/challenge.dart';

Map<String, dynamic> _challengeMap({
  double targetValue = 1000,
  double currentValue = 0,
  DateTime? endsAt,
  List<Map<String, dynamic>>? participants,
}) {
  return {
    'id': 'challenge-1',
    'title': 'Challenge 1000 arbres',
    'description': 'Plantons 1000 arbres ensemble',
    'target_value': targetValue,
    'current_value': currentValue,
    'unit': 'arbres',
    'ends_at': (endsAt ?? DateTime.now().add(const Duration(days: 30))).toIso8601String(),
    'action_categories': {
      'id': 'cat-1',
      'code': 'plantation',
      'label': 'Plantation',
      'icon': '🌳',
      'color': '#2E7D32',
    },
    'challenge_participants': participants ?? [],
  };
}

void main() {
  group('Challenge.fromMap', () {
    test('counts participants from the embedded list', () {
      final challenge = Challenge.fromMap(_challengeMap(participants: [
        {'profile_id': 'a'},
        {'profile_id': 'b'},
      ]));
      expect(challenge.participantsCount, 2);
    });

    test('isJoinedByMe is false when no current user is provided', () {
      final challenge = Challenge.fromMap(_challengeMap(participants: [
        {'profile_id': 'a'}
      ]));
      expect(challenge.isJoinedByMe, isFalse);
    });

    test('isJoinedByMe is true when the current user is among participants', () {
      final challenge = Challenge.fromMap(
        _challengeMap(participants: [
          {'profile_id': 'a'},
          {'profile_id': 'me'},
        ]),
        currentUserId: 'me',
      );
      expect(challenge.isJoinedByMe, isTrue);
    });

    test('category is null when the challenge has none', () {
      final map = _challengeMap()..['action_categories'] = null;
      expect(Challenge.fromMap(map).category, isNull);
    });
  });

  group('Challenge.progress', () {
    test('is 0 at the start', () {
      final challenge = Challenge.fromMap(_challengeMap(currentValue: 0, targetValue: 1000));
      expect(challenge.progress, 0);
    });

    test('is a fraction between 0 and 1 mid-way', () {
      final challenge = Challenge.fromMap(_challengeMap(currentValue: 250, targetValue: 1000));
      expect(challenge.progress, 0.25);
    });

    test('clamps at 1 even if current exceeds target', () {
      final challenge = Challenge.fromMap(_challengeMap(currentValue: 1200, targetValue: 1000));
      expect(challenge.progress, 1.0);
    });

    test('is 0 when the target is zero, never divides by zero', () {
      final challenge = Challenge.fromMap(_challengeMap(currentValue: 5, targetValue: 0));
      expect(challenge.progress, 0);
    });
  });

  group('Challenge.daysRemaining', () {
    test('is positive for a challenge ending in the future', () {
      final challenge = Challenge.fromMap(
        _challengeMap(endsAt: DateTime.now().add(const Duration(days: 10))),
      );
      expect(challenge.daysRemaining, greaterThanOrEqualTo(9));
    });

    test('is negative for a challenge that has already ended', () {
      final challenge = Challenge.fromMap(
        _challengeMap(endsAt: DateTime.now().subtract(const Duration(days: 2))),
      );
      expect(challenge.daysRemaining, lessThan(0));
    });
  });
}
