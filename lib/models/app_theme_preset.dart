import 'package:flutter/material.dart';

class AppColorPalette {
  final String id; // Unique identifier for saving
  final String name; // Display name, e.g., "Crimson"
  final Color seedColor;
  final Color swatchColor1Light; // First color for the UI picker in light mode
  final Color swatchColor2Light; // Second color for the UI picker in light mode
  final Color swatchColor1Dark;  // First color for the UI picker in dark mode
  final Color swatchColor2Dark;  // Second color for the UI picker in dark mode


  AppColorPalette({
    required this.id,
    required this.name,
    required this.seedColor,
    required this.swatchColor1Light,
    required this.swatchColor2Light,
    required this.swatchColor1Dark,
    required this.swatchColor2Dark,
  });
}

enum AppThemeMode {
  light,
  dark,
  system,
}