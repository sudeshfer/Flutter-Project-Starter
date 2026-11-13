import 'package:flutter/material.dart';

/// Brand colors. The theme derives full light/dark schemes from [seed].
abstract final class AppColors {
  static const Color seed = Color(0xFF3F51B5);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);

  /// Flavor banner colors (non-prod only).
  static const Color bannerDev = Color(0xFF2E7D32);
  static const Color bannerQa = Color(0xFFEF6C00);
  static const Color bannerStaging = Color(0xFF6A1B9A);
  static const Color bannerUat = Color(0xFF00897B);
}
