import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/profile/domain/profile.dart';

Map<String, dynamic> _profileMap({String? city, String? country, String? role}) => {
      'id': 'user-1',
      'username': 'fatima.verdia',
      'first_name': 'Fatima',
      'last_name': 'Ali',
      'avatar_url': null,
      'bio': null,
      'city': city,
      'country': country,
      'level': 1,
      'total_points': 65,
      'role': role,
    };

void main() {
  group('Profile.fromMap', () {
    test('parses identity and stats fields', () {
      final profile = Profile.fromMap(_profileMap());
      expect(profile.username, 'fatima.verdia');
      expect(profile.fullName, 'Fatima Ali');
      expect(profile.level, 1);
      expect(profile.totalPoints, 65);
    });
  });

  group('Profile.location', () {
    test('is null with no city and no country', () {
      expect(Profile.fromMap(_profileMap()).location, isNull);
    });

    test('joins city and country', () {
      final profile = Profile.fromMap(_profileMap(city: 'Moroni', country: 'Comores'));
      expect(profile.location, 'Moroni, Comores');
    });
  });

  group('Profile.copyWith', () {
    test('never lets a caller override level or totalPoints', () {
      // copyWith n'expose délibérément pas de paramètre level/totalPoints :
      // ces champs ne doivent jamais être modifiés autrement que par une
      // relecture depuis le serveur (voir Phase 8 — sécurité).
      final profile = Profile.fromMap(_profileMap());
      final updated = profile.copyWith(bio: 'Nouvelle bio');

      expect(updated.bio, 'Nouvelle bio');
      expect(updated.level, profile.level);
      expect(updated.totalPoints, profile.totalPoints);
    });

    test('keeps unspecified fields unchanged', () {
      final profile = Profile.fromMap(_profileMap(city: 'Moroni'));
      final updated = profile.copyWith(bio: 'Salut');

      expect(updated.city, 'Moroni');
      expect(updated.username, profile.username);
    });

    test('never lets a caller override role — it stays whatever it was', () {
      // Comme level/totalPoints : `role` ne peut être changé que via un
      // accès direct à la base (migration 0015, `revoke update (role)`).
      final profile = Profile.fromMap(_profileMap(role: 'moderator'));
      final updated = profile.copyWith(bio: 'Salut');

      expect(updated.isModerator, isTrue);
    });
  });

  group('Profile.isModerator', () {
    test('is false when role is absent (defaults to member)', () {
      expect(Profile.fromMap(_profileMap()).isModerator, isFalse);
    });

    test('is true when role is moderator', () {
      expect(Profile.fromMap(_profileMap(role: 'moderator')).isModerator, isTrue);
    });
  });
}
