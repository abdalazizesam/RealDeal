import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../models/app_theme_preset.dart'; // Import AppColorPalette and AppThemeMode
import 'settings/update_genre_preferences_screen.dart';
import 'settings/update_media_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';

  // --- Placeholder URLs ---
  final String _privacyPolicyUrl = 'https://github.com/abdalazizesam/RealDeal';
  final String _termsOfServiceUrl = 'https://github.com/abdalazizesam/RealDeal';
  // --- --- --- --- --- --- --- --- --- --- --- ---

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appVersion = 'Could not get version';
        });
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  void _showAboutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: Text('About ReelDeal', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'ReelDeal helps you discover great movies and TV shows.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  _appVersion,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(
                  'Developed with Flutter by Abdalaziz Esam.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(color: colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorPaletteSection(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selectedPaletteId = themeProvider.selectedColorPalette.id;

    // Limit to the first 4 available color palettes
    final displayedPalettes = ThemeProvider.availableColorPalettes.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column( // Use Column to stack Wrap and "..." text
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12.0, // Adjusted spacing for 4 circles
            runSpacing: 12.0, // Adjusted runSpacing
            alignment: WrapAlignment.start,
            children: displayedPalettes.asMap().entries.map((entry) {
              final index = entry.key;
              final palette = entry.value;
              bool isSelected = selectedPaletteId == palette.id;

              // Get dynamic swatch colors based on current effective brightness
              final Color swatch1 = themeProvider.getSwatchColor1(palette);
              final Color swatch2 = themeProvider.getSwatchColor2(palette);

              // Determine text/icon color for checkmark based on swatch background
              Color checkColor = ThemeData.estimateBrightnessForColor(swatch1) == Brightness.dark
                  ? Colors.white70
                  : Colors.black87;
              if (swatch1 == Colors.black) { // Specific for pure black
                checkColor = Colors.white70;
              }

              // Determine label text
              String labelText = index == 0 ? 'Default' : palette.name;

              return Column( // Wrap circle and text in a Column
                children: [
                  Tooltip(
                    message: palette.name,
                    preferBelow: false,
                    child: GestureDetector(
                      onTap: () {
                        themeProvider.selectColorPalette(palette.id);
                      },
                      child: Container(
                        width: 48, // Smaller width
                        height: 48, // Smaller height
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: swatch1.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(1,1),
                            )
                          ],
                        ),
                        child: ClipOval( // Clip content to oval shape
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(color: swatch1)),
                                    Expanded(child: Container(color: swatch2)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: swatch1.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.check_circle, color: checkColor, size: 24),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4), // Spacing between circle and text
                  SizedBox(
                    width: 60, // Give some width to the text to prevent overflow
                    child: Text(
                      labelText,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 16), // Spacing below the color circles
          if (ThemeProvider.availableColorPalettes.length > 4) // Only show "..." if there are more palettes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '...', // Indicate more options
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context); // Access ThemeProvider

    // Determine if OLED Black switch should be enabled
    final bool isOledBlackEnabled = themeProvider.selectedThemeMode == AppThemeMode.dark ||
        (themeProvider.selectedThemeMode == AppThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: <Widget>[
          _buildSectionHeader('Appearance', context),
          ListTile(
            title: Text('App Theme Color', style: textTheme.titleMedium),
            subtitle: Text('Choose your preferred color palette', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ),
          _buildColorPaletteSection(context),
          const SizedBox(height: 16), // Spacing between color palettes and dark mode

          // Dark Mode Section (using Card for Material 3 look)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 1, // Slight elevation
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: colorScheme.surfaceContainerLow, // Material 3 surface color
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Dark Mode', style: textTheme.bodyLarge), // Using bodyLarge for list tile titles
                    subtitle: Text('Choose how the app\'s theme adapts', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    trailing: DropdownButtonHideUnderline( // Hide default underline
                      child: DropdownButton<AppThemeMode>(
                        value: themeProvider.selectedThemeMode,
                        onChanged: (AppThemeMode? newValue) {
                          if (newValue != null) {
                            themeProvider.selectThemeMode(newValue);
                          }
                        },
                        items: AppThemeMode.values.map<DropdownMenuItem<AppThemeMode>>((AppThemeMode mode) {
                          String modeText;
                          switch (mode) {
                            case AppThemeMode.light:
                              modeText = 'Light';
                              break;
                            case AppThemeMode.dark:
                              modeText = 'Dark';
                              break;
                            case AppThemeMode.system:
                              modeText = 'Follow System';
                              break;
                          }
                          return DropdownMenuItem<AppThemeMode>(
                            value: mode,
                            child: Text(modeText, style: textTheme.bodyMedium), // Style dropdown text
                          );
                        }).toList(),
                        dropdownColor: colorScheme.surfaceContainerHigh, // Background for dropdown menu
                        icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.onSurfaceVariant), // Custom dropdown icon
                      ),
                    ),
                  ),
                  // OLED Black Switch (always visible, enabled/disabled based on theme)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'OLED Black',
                            style: textTheme.bodyLarge?.copyWith(
                              color: isOledBlackEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38), // Disabled color
                            ),
                          ),
                        ),
                        Switch(
                          value: themeProvider.isOledBlack,
                          onChanged: isOledBlackEnabled // Only enable if condition is true
                              ? (bool value) {
                            themeProvider.toggleOledBlack(value);
                          }
                              : null, // Set to null to disable the switch
                          activeColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.outline, // For disabled state thumb
                          inactiveTrackColor: colorScheme.surfaceContainerHighest, // For disabled state track
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),


          _buildSectionHeader('Preferences', context),
          _buildSettingsCard(context, [
            ListTile(
              leading: Icon(Icons.movie_filter_outlined, color: colorScheme.onSurfaceVariant),
              title: Text('Update Favorite Genres', style: textTheme.bodyLarge),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateGenrePreferencesScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library_outlined, color: colorScheme.onSurfaceVariant),
              title: Text('Update Favorite Movies/Shows', style: textTheme.bodyLarge),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateMediaPreferencesScreen()),
                );
              },
            ),
          ]),


          _buildSectionHeader('Information & Legal', context),
          _buildSettingsCard(context, [
            ListTile(
              leading: Icon(Icons.info_outline_rounded, color: colorScheme.onSurfaceVariant),
              title: Text('About ReelDeal', style: textTheme.bodyLarge),
              subtitle: Text(_appVersion, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              onTap: _showAboutDialog,
            ),
            ListTile(
              leading: Icon(Icons.shield_outlined, color: colorScheme.onSurfaceVariant),
              title: Text('Privacy Policy', style: textTheme.bodyLarge),
              onTap: () => _launchUrl(_privacyPolicyUrl),
            ),
            ListTile(
              leading: Icon(Icons.description_outlined, color: colorScheme.onSurfaceVariant),
              title: Text('Terms of Service', style: textTheme.bodyLarge),
              onTap: () => _launchUrl(_termsOfServiceUrl),
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // New helper widget for consistent card styling around ListTiles
  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: children,
      ),
    );
  }
}