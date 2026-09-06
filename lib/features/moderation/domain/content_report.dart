/// Motif de signalement d'un contenu (post/commentaire) — distinct de
/// `ReportType` (features/reports) qui couvre les problèmes environnementaux.
class ReportReason {
  static const spam = 'spam';
  static const contenuInapproprie = 'contenu_inapproprie';
  static const fausseAction = 'fausse_action';
  static const fraude = 'fraude';
  static const harcelement = 'harcelement';
  static const autre = 'autre';

  static const all = [
    spam,
    contenuInapproprie,
    fausseAction,
    fraude,
    harcelement,
    autre,
  ];

  static String label(String reason) {
    switch (reason) {
      case spam:
        return 'Spam';
      case contenuInapproprie:
        return 'Contenu inapproprié';
      case fausseAction:
        return 'Fausse action';
      case fraude:
        return 'Fraude';
      case harcelement:
        return 'Harcèlement';
      default:
        return 'Autre';
    }
  }
}

enum ReportTargetType {
  post,
  comment;

  String get value => switch (this) {
        ReportTargetType.post => 'post',
        ReportTargetType.comment => 'comment',
      };

  static ReportTargetType fromValue(String value) =>
      switch (value) { 'comment' => ReportTargetType.comment, _ => ReportTargetType.post };
}

class ReportStatus {
  static const pending = 'pending';
  static const reviewed = 'reviewed';
  static const dismissed = 'dismissed';

  static String label(String status) {
    switch (status) {
      case reviewed:
        return 'Traité';
      case dismissed:
        return 'Ignoré';
      default:
        return 'En attente';
    }
  }
}

/// Un signalement tel que consulté par un modérateur (voir
/// `ModerationRepository.fetchPendingReports`, réservé au rôle 'moderator' —
/// migration 0015). Distinct des méthodes d'écriture ci-dessus qui ne
/// requièrent, elles, qu'un simple insert par n'importe quel utilisateur.
class Report {
  const Report({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] as String,
      reporterId: map['reporter_id'] as String,
      targetType: ReportTargetType.fromValue(map['target_type'] as String),
      targetId: map['target_id'] as String,
      reason: map['reason'] as String,
      description: map['description'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;
}
