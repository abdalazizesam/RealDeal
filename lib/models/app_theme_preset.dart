import 'package:flutter/material.dart';

class AppColorPalette {
  final String id;
  final String name;
  final Color seedColor;
  final Color swatchColor1Light;
  final Color swatchColor2Light;
  final Color swatchColor1Dark;
  final Color swatchColor2Dark;


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