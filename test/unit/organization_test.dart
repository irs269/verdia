import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/organizations/domain/organization.dart';

void main() {
  group('OrganizationCategory', () {
    test('labels every known category', () {
      expect(OrganizationCategory.label(OrganizationCategory.association), 'Association');
      expect(OrganizationCategory.label(OrganizationCategory.ong), 'ONG');
      expect(OrganizationCategory.label(OrganizationCategory.entreprise), 'Entreprise');
      expect(OrganizationCategory.label(OrganizationCategory.ecole), 'École');
      expect(OrganizationCategory.label(OrganizationCategory.collectivite), 'Collectivité');
      expect(
        OrganizationCategory.label(OrganizationCategory.groupeCommunautaire),
        'Groupe communautaire',
      );
    });

    test('falls back to the raw value for an unknown category', () {
      expect(OrganizationCategory.label('inconnu'), 'inconnu');
    });
  });

  group('Organization.fromMap', () {
    test('parses a full row', () {
      final org = Organization.fromMap({
        'id': 'org-1',
        'name': 'Ulanga Comores',
        'logo_url': null,
        'description': 'Association environnementale',
        'category': OrganizationCategory.association,
        'city': 'Moroni',
        'country': 'Comores',
        'website': 'https://example.org',
        'verified': true,
      });

      expect(org.id, 'org-1');
      expect(org.name, 'Ulanga Comores');
      expect(org.verified, isTrue);
      expect(org.location, 'Moroni, Comores');
    });

    test('location is null when neither city nor country is set', () {
      final org = Organization.fromMap({
        'id': 'org-2',
        'name': 'École de Chindini',
        'logo_url': null,
        'description': 'École',
        'category': OrganizationCategory.ecole,
        'city': null,
        'country': null,
        'website': null,
        'verified': false,
      });

      expect(org.location, isNull);
    });
  });

  group('OrganizationMember.fromMap', () {
    test('joins profile fields and flags the owner', () {
      final member = OrganizationMember.fromMap({
        'profile_id': 'user-1',
        'role': 'owner',
        'profiles': {
          'username': 'ahmed.verdia',
          'first_name': 'Ahmed',
          'last_name': 'Said',
          'avatar_url': null,
        },
      });

      expect(member.username, 'ahmed.verdia');
      expect(member.fullName, 'Ahmed Said');
      expect(member.isOwner, isTrue);
    });

    test('isOwner is false for a plain member', () {
      final member = OrganizationMember.fromMap({
        'profile_id': 'user-2',
        'role': 'member',
        'profiles': {
          'username': 'fatima.verdia',
          'first_name': 'Fatima',
          'last_name': 'Ali',
          'avatar_url': null,
        },
      });

      expect(member.isOwner, isFalse);
    });
  });
}
