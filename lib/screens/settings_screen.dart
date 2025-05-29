import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../models/app_theme_preset.dart';
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

  Widget _buildColorPalette(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeId = themeProvider.currentTheme.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Wrap(
        spacing: 16.0,
        runSpacing: 16.0,
        alignment: WrapAlignment.start,
        children: ThemeProvider.availableThemePresets.map((preset) {
          bool isSelected = currentThemeId == preset.id;

          // Determine text/icon color for checkmark based on swatch background
          Color checkColor = ThemeData.estimateBrightnessForColor(preset.swatchColor1) == Brightness.dark
              ? Colors.white70
              : Colors.black87;
          if (preset.swatchColor1 == Colors.black) {
            checkColor = Colors.white70;
          }

          return Tooltip(
            message: preset.name,
            preferBelow: false,
            child: GestureDetector(
              onTap: () {
                themeProvider.selectThemePreset(preset.id);
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: preset.swatchColor1.withOpacity(0.4),
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
                            Expanded(child: Container(color: preset.swatchColor1)),
                            Expanded(child: Container(color: preset.swatchColor2)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: preset.swatchColor1.withOpacity(0.5),
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
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          _buildColorPalette(context),

          _buildSectionHeader('Preferences', context),
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

          _buildSectionHeader('Information & Legal', context),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}