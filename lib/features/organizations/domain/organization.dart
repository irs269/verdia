class OrganizationCategory {
  static const association = 'association';
  static const ong = 'ong';
  static const entreprise = 'entreprise';
  static const ecole = 'ecole';
  static const collectivite = 'collectivite';
  static const groupeCommunautaire = 'groupe_communautaire';

  static String label(String category) {
    switch (category) {
      case association:
        return 'Association';
      case ong:
        return 'ONG';
      case entreprise:
        return 'Entreprise';
      case ecole:
        return 'École';
      case collectivite:
        return 'Collectivité';
      case groupeCommunautaire:
        return 'Groupe communautaire';
      default:
        return category;
    }
  }

  static String icon(String category) {
    switch (category) {
      case association:
        return '🤝';
      case ong:
        return '🌍';
      case entreprise:
        return '🏢';
      case ecole:
        return '🏫';
      case collectivite:
        return '🏛️';
      case groupeCommunautaire:
        return '👥';
      default:
        return '🏢';
    }
  }
}

/// Reflète une ligne de `organizations`. Lecture seule pour l'instant — la
/// création suppose une vérification/modération dédiée hors du périmètre de
/// ce MVP (voir la migration 0013).
class Organization {
  const Organization({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.description,
    required this.category,
    this.city,
    this.country,
    this.website,
    required this.verified,
    required this.createdAt,
  });

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] as String,
      name: map['name'] as String,
      logoUrl: map['logo_url'] as String?,
      description: map['description'] as String,
      category: map['category'] as String,
      city: map['city'] as String?,
      country: map['country'] as String?,
      website: map['website'] as String?,
      verified: map['verified'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String name;
  final String? logoUrl;
  final String description;
  final String category;
  final String? city;
  final String? country;
  final String? website;
  final bool verified;
  final DateTime createdAt;

  String? get location {
    if (city == null && country == null) return null;
    return [city, country].where((e) => e != null && e.isNotEmpty).join(', ');
  }
}

/// Une ligne de `organization_members`, avec les infos de profil jointes pour
/// l'affichage (voir [OrganizationRepository.fetchMembers]).
class OrganizationMember {
  const OrganizationMember({
    required this.profileId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory OrganizationMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>;
    return OrganizationMember(
      profileId: map['profile_id'] as String,
      username: profile['username'] as String,
      fullName: '${profile['first_name']} ${profile['last_name']}',
      avatarUrl: profile['avatar_url'] as String?,
      role: map['role'] as String,
    );
  }

  final String profileId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final String role;

  bool get isOwner => role == 'owner';
}
