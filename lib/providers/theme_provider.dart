import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme_preset.dart';

class ThemeProvider with ChangeNotifier {
  static const String _selectedColorPaletteIdKey = 'selected_color_palette_id';
  static const String _selectedThemeModeKey = 'selected_theme_mode';
  static const String _isOledBlackKey = 'is_oled_black';

  // Define available color palettes with both light and dark swatches
  static final List<AppColorPalette> availableColorPalettes = [
    AppColorPalette(
        id: 'red', name: 'Crimson', seedColor: Colors.red,
        swatchColor1Light: Colors.red, swatchColor2Light: Colors.red.shade200,
        swatchColor1Dark: Colors.redAccent, swatchColor2Dark: Colors.red.shade700),
    AppColorPalette(
        id: 'blue', name: 'Azure', seedColor: Colors.blue,
        swatchColor1Light: Colors.blue, swatchColor2Light: Colors.blue.shade200,
        swatchColor1Dark: Colors.lightBlueAccent, swatchColor2Dark: Colors.blue.shade700),
    AppColorPalette(
        id: 'green', name: 'Forest', seedColor: Colors.green,
        swatchColor1Light: Colors.green, swatchColor2Light: Colors.green.shade200,
        swatchColor1Dark: Colors.lightGreenAccent, swatchColor2Dark: Colors.green.shade700),
    AppColorPalette(
        id: 'purple', name: 'Amethyst', seedColor: Colors.deepPurple,
        swatchColor1Light: Colors.deepPurple, swatchColor2Light: Colors.deepPurple.shade200,
        swatchColor1Dark: Colors.deepPurpleAccent, swatchColor2Dark: Colors.deepPurple.shade700),
    AppColorPalette(
        id: 'orange', name: 'Sunset', seedColor: Colors.orange,
        swatchColor1Light: Colors.orange, swatchColor2Light: Colors.orange.shade200,
        swatchColor1Dark: Colors.orangeAccent, swatchColor2Dark: Colors.orange.shade700),
    AppColorPalette(
        id: 'teal', name: 'Ocean', seedColor: Colors.teal,
        swatchColor1Light: Colors.teal, swatchColor2Light: Colors.teal.shade200,
        swatchColor1Dark: Colors.tealAccent, swatchColor2Dark: Colors.teal.shade700),
    AppColorPalette(
        id: 'indigo', name: 'Indigo', seedColor: Colors.indigoAccent,
        swatchColor1Light: Colors.indigo, swatchColor2Light: Colors.indigo.shade200,
        swatchColor1Dark: Colors.indigoAccent, swatchColor2Dark: Colors.indigo.shade700),
    AppColorPalette(
        id: 'cyan', name: 'Cyan', seedColor: Colors.cyanAccent,
        swatchColor1Light: Colors.cyan, swatchColor2Light: Colors.cyan.shade200,
        swatchColor1Dark: Colors.cyanAccent, swatchColor2Dark: Colors.cyan.shade700),
    AppColorPalette(
        id: 'amber', name: 'Amber', seedColor: Colors.amber,
        swatchColor1Light: Colors.amber, swatchColor2Light: Colors.amber.shade200,
        swatchColor1Dark: Colors.amberAccent, swatchColor2Dark: Colors.amber.shade700),
    AppColorPalette(
        id: 'lime', name: 'Lime', seedColor: Colors.limeAccent,
        swatchColor1Light: Colors.lime, swatchColor2Light: Colors.lime.shade200,
        swatchColor1Dark: Colors.limeAccent, swatchColor2Dark: Colors.lime.shade700),
    AppColorPalette(
        id: 'pink', name: 'Pink', seedColor: Colors.pinkAccent,
        swatchColor1Light: Colors.pink, swatchColor2Light: Colors.pink.shade200,
        swatchColor1Dark: Colors.pinkAccent, swatchColor2Dark: Colors.pink.shade700),
  ];

  AppColorPalette _selectedColorPalette = availableColorPalettes.firstWhere((p) => p.id == 'red');
  AppThemeMode _selectedThemeMode = AppThemeMode.system;
  bool _isOledBlack = false;

  SharedPreferences? _prefs;

  ThemeProvider() {
    _loadThemePreferences();
  }

  AppColorPalette get selectedColorPalette => _selectedColorPalette;
  AppThemeMode get selectedThemeMode => _selectedThemeMode;
  bool get isOledBlack => _isOledBlack;

  // The actual Brightness to use for MaterialApp
  Brightness get effectiveBrightness {
    if (_selectedThemeMode == AppThemeMode.system) {
      // This will be determined by the system in main.dart
      return WidgetsBinding.instance.window.platformBrightness;
    }
    return _selectedThemeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  // Explicit background/surface colors for OLED black mode
  Color? get explicitBackgroundColor => _isOledBlack && effectiveBrightness == Brightness.dark ? Colors.black : null;
  Color? get explicitSurfaceColor => _isOledBlack && effectiveBrightness == Brightness.dark ? const Color(0xFF121212) : null;

  // New helper to get the correct swatch colors based on current effective brightness
  Color getSwatchColor1(AppColorPalette palette) {
    return effectiveBrightness == Brightness.dark ? palette.swatchColor1Dark : palette.swatchColor1Light;
  }

  Color getSwatchColor2(AppColorPalette palette) {
    return effectiveBrightness == Brightness.dark ? palette.swatchColor2Dark : palette.swatchColor2Light;
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadThemePreferences() async {
    await _initPrefs();
    final String? colorPaletteId = _prefs?.getString(_selectedColorPaletteIdKey);
    final String? themeModeString = _prefs?.getString(_selectedThemeModeKey);
    final bool? oledBlack = _prefs?.getBool(_isOledBlackKey);

    if (colorPaletteId != null) {
      _selectedColorPalette = availableColorPalettes.firstWhere(
            (palette) => palette.id == colorPaletteId,
        orElse: () => availableColorPalettes.firstWhere((p) => p.id == 'red'),
      );
    }

    if (themeModeString != null) {
      _selectedThemeMode = AppThemeMode.values.firstWhere(
            (e) => e.name == themeModeString,
        orElse: () => AppThemeMode.system,
      );
    }

    _isOledBlack = oledBlack ?? false;

    notifyListeners();
  }

  Future<void> selectColorPalette(String id) async {
    final newPalette = availableColorPalettes.firstWhere(
            (palette) => palette.id == id,
        orElse: () => _selectedColorPalette
    );

    if (_selectedColorPalette.id == newPalette.id) return;

    _selectedColorPalette = newPalette;
    await _initPrefs();
    await _prefs?.setString(_selectedColorPaletteIdKey, newPalette.id);
    notifyListeners();
  }

  Future<void> selectThemeMode(AppThemeMode mode) async {
    if (_selectedThemeMode == mode) return;

    _selectedThemeMode = mode;
    await _initPrefs();
    await _prefs?.setString(_selectedThemeModeKey, mode.name);
    notifyListeners();
  }

  Future<void> toggleOledBlack(bool value) async {
    if (_isOledBlack == value) return;

    _isOledBlack = value;
    await _initPrefs();
    await _prefs?.setBool(_isOledBlackKey, value);
    notifyListeners();
  }
}