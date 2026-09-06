import 'action_category.dart';

class EcoAction {
  const EcoAction({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.quantity,
    this.quantityUnit,
    required this.participantsCount,
    this.city,
    this.country,
    this.lat,
    this.lng,
    required this.occurredAt,
    required this.status,
    this.impactPoints,
  });

  factory EcoAction.fromMap(Map<String, dynamic> map) {
    final impactPointsList = map['impact_points'] as List?;
    return EcoAction(
      id: map['id'] as String,
      category: ActionCategory.fromMap(map['action_categories'] as Map<String, dynamic>),
      title: map['title'] as String,
      description: map['description'] as String,
      quantity: (map['quantity'] as num?)?.toDouble(),
      quantityUnit: map['quantity_unit'] as String?,
      participantsCount: map['participants_count'] as int,
      city: map['city'] as String?,
      country: map['country'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      status: map['status'] as String,
      impactPoints: (impactPointsList != null && impactPointsList.isNotEmpty)
          ? impactPointsList.first['points'] as int
          : null,
    );
  }

  final String id;
  final ActionCategory category;
  final String title;
  final String description;
  final double? quantity;
  final String? quantityUnit;
  final int participantsCount;
  final String? city;
  final String? country;
  final double? lat;
  final double? lng;
  final DateTime occurredAt;
  final String status;
  final int? impactPoints;

  String? get quantityLabel {
    if (quantity == null) return null;
    final formatted = quantity == quantity!.roundToDouble()
        ? quantity!.toInt().toString()
        : quantity.toString();
    return quantityUnit != null ? '$formatted $quantityUnit' : formatted;
  }
}
