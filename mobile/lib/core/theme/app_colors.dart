import 'package:flutter/material.dart';

abstract final class AppColors {
  // Light Mode
  static const primary = Color(0xFF2F6B4F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F5EF);
  static const onSurface = Color(0xFF1B2420);
  static const accent = Color(0xFFE9B44C);
  static const onAccent = Color(0xFF2A2000);
  static const error = Color(0xFFC4533A);

  // Dark Mode
  static const primaryDark = Color(0xFF7FC8A0);
  static const onPrimaryDark = Color(0xFF0B2316);
  static const surfaceDark = Color(0xFF121A16);
  static const onSurfaceDark = Color(0xFFE6EBE7);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppRadius {
  static const md = 16.0;
  static const lg = 24.0;
}
