import 'package:flutter/material.dart';

class ActionCategory {
  const ActionCategory({
    required this.id,
    required this.code,
    required this.label,
    required this.icon,
    required this.color,
  });

  factory ActionCategory.fromMap(Map<String, dynamic> map) {
    return ActionCategory(
      id: map['id'] as String,
      code: map['code'] as String,
      label: map['label'] as String,
      icon: map['icon'] as String,
      color: _parseColor(map['color'] as String),
    );
  }

  final String id;
  final String code;
  final String label;
  final String icon;
  final Color color;

  static Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}
