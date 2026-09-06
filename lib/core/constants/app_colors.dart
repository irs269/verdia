import 'package:flutter/material.dart';

/// VERDIA brand palette — nature, technologie, communauté.
abstract final class AppColors {
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color accent = Color(0xFF81C784);

  static const Color background = Color(0xFFFAFBFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F4F1);

  static const Color textPrimary = Color(0xFF1B1D1B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE3E7E3);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF9A825);
  static const Color info = Color(0xFF2196F3);

  // Catégories d'actions écologiques (fallback tant que action_categories
  // n'est pas chargé depuis Supabase).
  static const Color categoryPlantation = Color(0xFF2E7D32);
  static const Color categoryCleaning = Color(0xFF00897B);
  static const Color categoryRecycling = Color(0xFF7CB342);
  static const Color categoryWater = Color(0xFF0288D1);
  static const Color categoryPollution = Color(0xFFEF6C00);
  static const Color categoryCommunity = Color(0xFF8E24AA);
}
