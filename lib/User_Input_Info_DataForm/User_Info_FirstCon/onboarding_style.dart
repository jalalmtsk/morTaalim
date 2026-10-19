import 'package:flutter/material.dart';

/// Shared look for the first-launch onboarding (UserInfoForm pages).
/// The sky/cream background is painted once by [UserInfoForm]; every page
/// keeps a transparent Scaffold so it shows through.
class Onb {
  Onb._();

  static const String background = 'assets/images/UI/BackGrounds/onboarding_sky_bg.jpg';
  static const Color bgFallback = Color(0xFFFEFDF5); // cream, matches image bottom

  // Text on the light background
  static const Color title = Color(0xFF1E3A5F);      // deep navy
  static const Color body = Color(0xFF4A6075);       // soft slate
  static const Color accent = Colors.deepOrange;

  // Cards / tiles
  static Color card = Colors.white.withOpacity(0.85);
  static Color cardSelected = Colors.white;
  static const Color cardBorder = Color(0xFFBFE3F8);  // light sky
  static const Color cardBorderSelected = Color(0xFF4FB3E8);

  static const List<Shadow> titleShadow = [
    Shadow(color: Colors.white70, blurRadius: 6, offset: Offset(0, 1)),
  ];
}
