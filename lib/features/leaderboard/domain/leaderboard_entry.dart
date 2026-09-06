class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.totalPoints,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'] as String,
      username: map['username'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      totalPoints: map['total_points'] as int,
    );
  }

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final int totalPoints;

  String get fullName => '$firstName $lastName';
}
