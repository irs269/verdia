class EcoBadge {
  const EcoBadge({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    this.earnedAt,
  });

  factory EcoBadge.fromMap(Map<String, dynamic> map, {DateTime? earnedAt}) {
    return EcoBadge(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      earnedAt: earnedAt,
    );
  }

  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final DateTime? earnedAt;

  bool get isUnlocked => earnedAt != null;
}
