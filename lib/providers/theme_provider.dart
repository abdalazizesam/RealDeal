import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme_preset.dart';

class ThemeProvider with ChangeNotifier {
  static const String _selectedThemeIdKey = 'selected_theme_id';

  // Define Theme Presets
  static final List<AppThemePreset> availableThemePresets = [
    // Light Themes (6)
    AppThemePreset(id: 'red_light', name: 'Crimson Light', seedColor: Colors.red, swatchColor1: Colors.red, swatchColor2: Colors.red.shade200, brightness: Brightness.light),
    AppThemePreset(id: 'blue_light', name: 'Azure Light', seedColor: Colors.blue, swatchColor1: Colors.blue, swatchColor2: Colors.blue.shade200, brightness: Brightness.light),
    AppThemePreset(id: 'green_light', name: 'Forest Light', seedColor: Colors.green, swatchColor1: Colors.green, swatchColor2: Colors.green.shade200, brightness: Brightness.light),
    AppThemePreset(id: 'purple_light', name: 'Amethyst Light', seedColor: Colors.deepPurple, swatchColor1: Colors.deepPurple, swatchColor2: Colors.deepPurple.shade200, brightness: Brightness.light),
    AppThemePreset(id: 'orange_light', name: 'Sunset Light', seedColor: Colors.orange, swatchColor1: Colors.orange, swatchColor2: Colors.orange.shade200, brightness: Brightness.light),
    AppThemePreset(id: 'teal_light', name: 'Ocean Light', seedColor: Colors.teal, swatchColor1: Colors.teal, swatchColor2: Colors.teal.shade200, brightness: Brightness.light),

    // Dark Themes - Gray Background (3)
    AppThemePreset(id: 'red_dark_gray', name: 'Ruby Dark', seedColor: Colors.redAccent, swatchColor1: Colors.redAccent, swatchColor2: const Color(0xFF1F1F1F), brightness: Brightness.dark), // Explicit dark gray for swatch2
    AppThemePreset(id: 'indigo_dark_gray', name: 'Indigo Night', seedColor: Colors.indigoAccent, swatchColor1: Colors.indigoAccent, swatchColor2: const Color(0xFF1F1F1F), brightness: Brightness.dark),
    AppThemePreset(id: 'cyan_dark_gray', name: 'Cyber Dark', seedColor: Colors.cyanAccent, swatchColor1: Colors.cyanAccent, swatchColor2: const Color(0xFF1F1F1F), brightness: Brightness.dark),

    // Dark Themes - True Black Background (3)
    AppThemePreset(id: 'gold_on_black', name: 'Gold on Black', seedColor: Colors.amber, swatchColor1: Colors.amber, swatchColor2: Colors.black, brightness: Brightness.dark, explicitBackgroundColor: Colors.black, explicitSurfaceColor: const Color(0xFF121212)), // Deeper surface for true black
    AppThemePreset(id: 'lime_on_black', name: 'Lime on Black', seedColor: Colors.limeAccent, swatchColor1: Colors.limeAccent, swatchColor2: Colors.black, brightness: Brightness.dark, explicitBackgroundColor: Colors.black, explicitSurfaceColor: const Color(0xFF121212)),
    AppThemePreset(id: 'pink_on_black', name: 'Hot Pink on Black', seedColor: Colors.pinkAccent, swatchColor1: Colors.pinkAccent, swatchColor2: Colors.black, brightness: Brightness.dark, explicitBackgroundColor: Colors.black, explicitSurfaceColor: const Color(0xFF121212)),
  ];

  // Explicitly set a default preset that exists in the list
  AppThemePreset _currentThemePreset = availableThemePresets.firstWhere((p) => p.id == 'red_dark_gray'); // Default to Ruby Dark

  SharedPreferences? _prefs;

  ThemeProvider() {
    _loadSelectedTheme();
  }

  AppThemePreset get currentTheme => _currentThemePreset;
  List<AppThemePreset> get availablePresets => availableThemePresets;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadSelectedTheme() async {
    await _initPrefs();
    final String? themeId = _prefs?.getString(_selectedThemeIdKey);
    if (themeId != null) {
      final loadedPreset = availableThemePresets.firstWhere(
              (preset) => preset.id == themeId,
          orElse: () => availableThemePresets.firstWhere((p) => p.id == 'red_dark_gray') // Fallback to default if ID not found
      );
      _currentThemePreset = loadedPreset;
    }
    notifyListeners(); // Ensure listeners are notified on load
  }

  Future<void> selectThemePreset(String themeId) async {
    final newPreset = availableThemePresets.firstWhere(
            (preset) => preset.id == themeId,
        orElse: () => _currentThemePreset // Should not happen if UI provides valid IDs
    );

    if (_currentThemePreset.id == newPreset.id) return;

    _currentThemePreset = newPreset;
    notifyListeners();

    await _initPrefs();
    await _prefs?.setString(_selectedThemeIdKey, newPreset.id);
  }
}