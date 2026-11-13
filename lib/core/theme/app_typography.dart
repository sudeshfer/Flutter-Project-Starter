import 'package:flutter/material.dart';

/// Typography overrides on top of Material 3 defaults.
abstract final class AppTypography {
  static TextTheme textTheme(TextTheme base) => base.copyWith(
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}
