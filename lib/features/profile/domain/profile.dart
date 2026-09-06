/// Reflète une ligne de la table `profiles`.
class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.country,
    required this.level,
    required this.totalPoints,
    this.role = 'member',
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      username: map['username'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      level: map['level'] as int,
      totalPoints: map['total_points'] as int,
      role: map['role'] as String? ?? 'member',
    );
  }

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final String? country;
  final int level;
  final int totalPoints;
  final String role;

  String get fullName => '$firstName $lastName';

  /// `role` ne peut être changé que via un accès direct à la base (voir
  /// migration 0015 — `revoke update (role)`) : jamais via [Profile.copyWith]
  /// ni aucun appel client.
  bool get isModerator => role == 'moderator';

  String? get location {
    if (city == null && country == null) return null;
    return [city, country].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  Profile copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? city,
    String? country,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      country: country ?? this.country,
      level: level,
      totalPoints: totalPoints,
      role: role,
    );
  }
}
