import 'package:flutter/material.dart';

class AppThemePreset {
  final String id; // Unique identifier for saving
  final String name; // Display name, e.g., "Crimson Light"
  final Color seedColor;
  final Color swatchColor1; // For the UI picker
  final Color swatchColor2; // Second color for the UI picker
  final Brightness brightness;
  final Color? explicitBackgroundColor; // For true black or custom dark backgrounds
  final Color? explicitSurfaceColor; // For cards/dialogs in true black themes

  AppThemePreset({
    required this.id,
    required this.name,
    required this.seedColor,
    required this.swatchColor1,
    required this.swatchColor2,
    required this.brightness,
    this.explicitBackgroundColor,
    this.explicitSurfaceColor,
  });
}