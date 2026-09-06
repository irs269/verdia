class ReportType {
  static const depotSauvage = 'depot_sauvage';
  static const pollution = 'pollution';
  static const deforestation = 'deforestation';
  static const eauPolluee = 'eau_polluee';
  static const dechets = 'dechets';
  static const destructionEspace = 'destruction_espace';
  static const autre = 'autre';

  static const all = [
    depotSauvage,
    pollution,
    deforestation,
    eauPolluee,
    dechets,
    destructionEspace,
    autre,
  ];

  static String label(String type) {
    switch (type) {
      case depotSauvage:
        return 'Dépôt sauvage';
      case pollution:
        return 'Pollution';
      case deforestation:
        return 'Déforestation';
      case eauPolluee:
        return 'Eau polluée';
      case dechets:
        return 'Déchets';
      case destructionEspace:
        return "Destruction d'espace naturel";
      default:
        return 'Autre';
    }
  }

  static String icon(String type) {
    switch (type) {
      case depotSauvage:
        return '🗑️';
      case pollution:
        return '🏭';
      case deforestation:
        return '🪓';
      case eauPolluee:
        return '💧';
      case dechets:
        return '♻️';
      case destructionEspace:
        return '⚠️';
      default:
        return '📍';
    }
  }
}

class ReportStatus {
  static const signale = 'signale';
  static const enVerification = 'en_verification';
  static const enCours = 'en_cours';
  static const resolu = 'resolu';
  static const rejete = 'rejete';

  static String label(String status) {
    switch (status) {
      case signale:
        return 'Signalé';
      case enVerification:
        return 'En vérification';
      case enCours:
        return 'En cours';
      case resolu:
        return 'Résolu';
      case rejete:
        return 'Rejeté';
      default:
        return status;
    }
  }
}

class EnvironmentalReport {
  const EnvironmentalReport({
    required this.id,
    required this.type,
    required this.description,
    this.photoUrl,
    required this.lat,
    required this.lng,
    this.city,
    this.country,
    required this.status,
    required this.createdAt,
  });

  factory EnvironmentalReport.fromMap(Map<String, dynamic> map) {
    return EnvironmentalReport(
      id: map['id'] as String,
      type: map['type'] as String,
      description: map['description'] as String,
      photoUrl: map['photo_url'] as String?,
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      city: map['city'] as String?,
      country: map['country'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String type;
  final String description;
  final String? photoUrl;
  final double lat;
  final double lng;
  final String? city;
  final String? country;
  final String status;
  final DateTime createdAt;
}
