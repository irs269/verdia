import '../../posts/domain/post.dart';

class Event {
  const Event({
    required this.id,
    required this.organizer,
    required this.title,
    required this.description,
    this.coverUrl,
    required this.lat,
    required this.lng,
    this.city,
    this.country,
    required this.startsAt,
    this.endsAt,
    this.targetParticipants,
    required this.status,
    required this.participantsCount,
    required this.isJoinedByMe,
    this.organizerOrgId,
    this.organizerOrgName,
    this.organizerOrgLogoUrl,
  });

  factory Event.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final participants = map['event_participants'] as List? ?? [];
    final isJoined = currentUserId != null &&
        participants.any((p) => (p as Map<String, dynamic>)['profile_id'] == currentUserId);
    final org = map['organizations'] as Map<String, dynamic>?;
    return Event(
      id: map['id'] as String,
      organizer: PostAuthor.fromMap(
        map['organizer_id'] as String,
        map['profiles'] as Map<String, dynamic>,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      coverUrl: map['cover_url'] as String?,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      city: map['city'] as String?,
      country: map['country'] as String?,
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: map['ends_at'] != null ? DateTime.parse(map['ends_at'] as String) : null,
      targetParticipants: map['target_participants'] as int?,
      status: map['status'] as String,
      participantsCount: participants.length,
      isJoinedByMe: isJoined,
      organizerOrgId: map['organizer_org_id'] as String?,
      organizerOrgName: org?['name'] as String?,
      organizerOrgLogoUrl: org?['logo_url'] as String?,
    );
  }

  final String id;
  final PostAuthor organizer;
  final String title;
  final String description;
  final String? coverUrl;
  final double lat;
  final double lng;
  final String? city;
  final String? country;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int? targetParticipants;
  final String status;
  final int participantsCount;
  final bool isJoinedByMe;

  /// Renseignés si l'événement a été publié au nom d'une organisation — voir
  /// audit, item "Création de campagnes par une organisation" (migration
  /// 0023). `null` = événement porté par le profil [organizer] lui-même.
  final String? organizerOrgId;
  final String? organizerOrgName;
  final String? organizerOrgLogoUrl;

  String? get location {
    if (city == null && country == null) return null;
    return [city, country].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  /// `null` tant qu'aucun objectif de participants n'a été fixé — dans ce
  /// cas [EventCard] n'affiche pas de barre de progression.
  double? get progress {
    if (targetParticipants == null || targetParticipants! <= 0) return null;
    return (participantsCount / targetParticipants!).clamp(0, 1);
  }

  Event copyWith({int? participantsCount, bool? isJoinedByMe}) {
    return Event(
      id: id,
      organizer: organizer,
      title: title,
      description: description,
      coverUrl: coverUrl,
      lat: lat,
      lng: lng,
      city: city,
      country: country,
      startsAt: startsAt,
      endsAt: endsAt,
      targetParticipants: targetParticipants,
      status: status,
      participantsCount: participantsCount ?? this.participantsCount,
      isJoinedByMe: isJoinedByMe ?? this.isJoinedByMe,
      organizerOrgId: organizerOrgId,
      organizerOrgName: organizerOrgName,
      organizerOrgLogoUrl: organizerOrgLogoUrl,
    );
  }
}
