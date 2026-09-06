import '../../actions/domain/action_category.dart';

class Challenge {
  const Challenge({
    required this.id,
    this.category,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.endsAt,
    required this.participantsCount,
    required this.isJoinedByMe,
  });

  factory Challenge.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final participants = map['challenge_participants'] as List? ?? [];
    final isJoined = currentUserId != null &&
        participants.any((p) => (p as Map<String, dynamic>)['profile_id'] == currentUserId);
    return Challenge(
      id: map['id'] as String,
      category: map['action_categories'] != null
          ? ActionCategory.fromMap(map['action_categories'] as Map<String, dynamic>)
          : null,
      title: map['title'] as String,
      description: map['description'] as String,
      targetValue: (map['target_value'] as num).toDouble(),
      currentValue: (map['current_value'] as num).toDouble(),
      unit: map['unit'] as String,
      endsAt: DateTime.parse(map['ends_at'] as String),
      participantsCount: participants.length,
      isJoinedByMe: isJoined,
    );
  }

  final String id;
  final ActionCategory? category;
  final String title;
  final String description;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime endsAt;
  final int participantsCount;
  final bool isJoinedByMe;

  double get progress => targetValue <= 0 ? 0 : (currentValue / targetValue).clamp(0, 1);

  int get daysRemaining => endsAt.difference(DateTime.now()).inDays;

  Challenge copyWith({int? participantsCount, bool? isJoinedByMe}) {
    return Challenge(
      id: id,
      category: category,
      title: title,
      description: description,
      targetValue: targetValue,
      currentValue: currentValue,
      unit: unit,
      endsAt: endsAt,
      participantsCount: participantsCount ?? this.participantsCount,
      isJoinedByMe: isJoinedByMe ?? this.isJoinedByMe,
    );
  }
}
