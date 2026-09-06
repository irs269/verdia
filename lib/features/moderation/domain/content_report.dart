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
}
