import 'package:flutter/material.dart';

/// Design tokens & semantic color system for RentKhata
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0D9488); // Teal 600 - Trust & Money
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFFCCFBF1); // Teal 100
  static const Color secondary = Color(0xFF4F46E5); // Indigo 600

  // Semantic Status Colors (Crucial for Landlord Room Grid)
  static const Color statusPaid = Color(0xFF16A34A); // Emerald Green 600 (Paid / ₹0 Due)
  static const Color statusPaidLight = Color(0xFFDCFCE7); // Green 100 background
  
  static const Color statusOverdue = Color(0xFFDC2626); // Ruby Red 600 (Late Rent)
  static const Color statusOverdueLight = Color(0xFFFEE2E2); // Red 100 background
  
  static const Color statusDueToday = Color(0xFFD97706); // Amber 600 (Due today / Partial)
  static const Color statusDueTodayLight = Color(0xFFFEF3C7); // Amber 100 background
  
  static const Color statusVacant = Color(0xFF64748B); // Slate 500 (Empty bed/room)
  static const Color statusVacantLight = Color(0xFFF1F5F9); // Slate 100 background

  // Neutrals & Backgrounds
  static const Color background = Color(0xFFF8FAFC); // Slate 50 - Soft on eyes
  static const Color cardSurface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFCBD5E1); // Slate 300
}
