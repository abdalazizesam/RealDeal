import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/theme_provider.dart';
import '../providers/library_provider.dart';
import '../models/app_theme_preset.dart';
import '../models/media_item.dart';
import 'settings/update_genre_preferences_screen.dart';
import 'settings/update_media_preferences_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';

  final String _privacyPolicyUrl = 'https://github.com/abdalazizesam/RealDeal';
  final String _termsOfServiceUrl = 'https://github.com/abdalazizesam/RealDeal';

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
    HapticFeedback.lightImpact();
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
                HapticFeedback.lightImpact();
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

    final displayedPalettes = ThemeProvider.availableColorPalettes.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.start,
            children: displayedPalettes.asMap().entries.map((entry) {
              final index = entry.key;
              final palette = entry.value;
              bool isSelected = selectedPaletteId == palette.id;

              final Color swatch1 = themeProvider.getSwatchColor1(palette);
              final Color swatch2 = themeProvider.getSwatchColor2(palette);

              Color checkColor = ThemeData.estimateBrightnessForColor(swatch1) == Brightness.dark
                  ? Colors.white70
                  : Colors.black87;
              if (swatch1 == Colors.black) {
                checkColor = Colors.white70;
              }

              String labelText = index == 0 ? 'Default' : palette.name;

              return Column(
                children: [
                  Tooltip(
                    message: palette.name,
                    preferBelow: false,
                    child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          themeProvider.selectColorPalette(palette.id);
                        },
                        child: Container(
                          width: 48,
                          height: 48,
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
              child: ClipOval(
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
              const SizedBox(height: 4),
              SizedBox(
              width: 60,
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
          const SizedBox(height: 16),
          if (ThemeProvider.availableColorPalettes.length > 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                '...',
                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  // _exportLibrary: Uses FilePicker.platform.saveFile for robust export.
  // Updated: Changed success message for better user clarity.
  Future<void> _exportLibrary(BuildContext context) async {
    HapticFeedback.lightImpact();
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      final List<Map<String, dynamic>> libraryData =
      libraryProvider.libraryItems.map((item) => item.toJson()).toList();
      final String jsonString = json.encode(libraryData);

      final fileName = 'reeldeallibrary_${DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-')}.json';

      // Use FilePicker.platform.saveFile for saving. This handles permissions and directory selection for modern Android.
      // It will open a system dialog for the user to choose the save location.
      String? outputFile = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonString), // Pass content as bytes to be saved
      );

      if (outputFile == null) {
        // User cancelled the picker
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Library export cancelled.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              backgroundColor: colorScheme.surfaceVariant,
            ),
          );
        }
        return;
      }

      // Updated success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Library exported successfully to the chosen location!',
                style: TextStyle(color: colorScheme.onSecondaryContainer)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: colorScheme.secondaryContainer,
            duration: const Duration(seconds: 4), // Shortened duration as path is not directly shown
          ),
        );
      }
    } catch (e) {
      print('Error exporting library: $e'); // Log the actual error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export library: ${e.toString().contains("PlatformException") ? "Operation cancelled or denied." : e.toString()}', // More user-friendly error message
                style: TextStyle(color: colorScheme.onErrorContainer)),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  // MODIFIED: _importLibrary to explicitly request MANAGE_EXTERNAL_STORAGE for Android 11+
  // WARNING: This permission is highly restricted by Google Play Store policies.
  Future<void> _importLibrary(BuildContext context) async {
    HapticFeedback.lightImpact();
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    try {
      // Check Android platform and API level to request appropriate permissions
      if (defaultTargetPlatform == TargetPlatform.android) {
        final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin(); // Instantiate DeviceInfoPlugin
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        final int sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) { // Android 11 (API 30) and above
          final status = await Permission.manageExternalStorage.request();
          print('MANAGE_EXTERNAL_STORAGE status: $status'); // Log the status

          if (status.isDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All Files Access permission denied. Cannot import library.',
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                  backgroundColor: colorScheme.errorContainer,
                ),
              );
            }
            return;
          }
          if (status.isPermanentlyDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All Files Access permission permanently denied. Please enable it in app settings manually.',
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                  action: SnackBarAction(label: 'Settings', onPressed: openAppSettings, textColor: colorScheme.onErrorContainer),
                  backgroundColor: colorScheme.errorContainer,
                ),
              );
            }
            return;
          }
        } else {
          // For Android versions below 11 (API < 30)
          final status = await Permission.storage.request();
          print('Standard Storage permission status: $status'); // Log the status
          if (status.isDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Storage permission denied by user. Please grant permission to import library.',
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                  backgroundColor: colorScheme.errorContainer,
                ),
              );
            }
            return;
          }
          if (status.isPermanentlyDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Storage permission permanently denied. Please enable it in app settings manually.',
                      style: TextStyle(color: colorScheme.onErrorContainer)),
                  action: SnackBarAction(label: 'Settings', onPressed: openAppSettings, textColor: colorScheme.onErrorContainer),
                  backgroundColor: colorScheme.errorContainer,
                ),
              );
            }
            return;
          }
        }
      } // End of Android platform check

      // If permissions are granted (or not needed for the OS), proceed to pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selection cancelled.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              backgroundColor: colorScheme.surfaceVariant,
            ),
          );
        }
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected file path is invalid.', style: TextStyle(color: colorScheme.onErrorContainer)),
              backgroundColor: colorScheme.errorContainer,
            ),
          );
        }
        return;
      }

      final file = File(filePath);

      // 2. Read file content
      final String jsonString = await file.readAsString();

      // 3. Decode JSON and convert to MediaItem list
      final List<dynamic> decodedList = json.decode(jsonString);
      List<MediaItem> importedItems = [];
      for (var itemJson in decodedList) {
        try {
          importedItems.add(MediaItem.fromJson(itemJson));
        } catch (e) {
          print('Error parsing item during import: $e. Skipping item: $itemJson');
          // Optionally show a warning for malformed items
        }
      }

      // 4. Confirm with user before replacing/merging
      bool confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: colorScheme.surfaceContainerHigh,
            title: Text('Import Library?', style: textTheme.titleLarge),
            content: Text(
              'This will replace your current library with ${importedItems.length} items from the selected file. This action cannot be undone. Are you sure?',
              style: textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(dialogContext, false);
                },
                child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(dialogContext, true);
                },
                child: Text('Import', style: TextStyle(color: colorScheme.error)),
              ),
            ],
          );
        },
      ) ?? false;

      if (!confirm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Library import cancelled.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              backgroundColor: colorScheme.surfaceVariant,
            ),
          );
        }
        return;
      }

      // 5. Update library (replace existing for simplicity; merging is more complex)
      libraryProvider.replaceAllLibraryItems(importedItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Library imported successfully! ${importedItems.length} items loaded.', style: TextStyle(color: colorScheme.onSecondaryContainer)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: colorScheme.secondaryContainer,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error importing library: $e'); // Log the actual error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import library: ${e.toString()}', style: TextStyle(color: colorScheme.onErrorContainer)),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          const SizedBox(height: 16),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Dark Mode', style: textTheme.bodyLarge),
                    subtitle: Text('Choose how the app\'s theme adapts', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<AppThemeMode>(
                        value: themeProvider.selectedThemeMode,
                        onChanged: (AppThemeMode? newValue) {
                          HapticFeedback.lightImpact();
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
                            child: Text(modeText, style: textTheme.bodyMedium),
                          );
                        }).toList(),
                        dropdownColor: colorScheme.surfaceContainerHigh,
                        icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'OLED Black',
                            style: textTheme.bodyLarge?.copyWith(
                              color: isOledBlackEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                        ),
                        Switch(
                          value: themeProvider.isOledBlack,
                          onChanged: isOledBlackEnabled
                              ? (bool value) {
                            HapticFeedback.lightImpact();
                            themeProvider.toggleOledBlack(value);
                          }
                              : null,
                          activeColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.outline,
                          inactiveTrackColor: colorScheme.surfaceContainerHighest,
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
                HapticFeedback.lightImpact();
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
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateMediaPreferencesScreen()),
                );
              },
            ),
          ]),

          // Library Data Management Section
          _buildSectionHeader('Library Data', context),
          _buildSettingsCard(context, [
            ListTile(
              leading: Icon(Icons.file_upload_rounded, color: colorScheme.onSurfaceVariant),
              title: Text('Import Library', style: textTheme.bodyLarge),
              subtitle: Text('Load library data from a file', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              onTap: () => _importLibrary(context),
            ),
            ListTile(
              leading: Icon(Icons.file_download_rounded, color: colorScheme.onSurfaceVariant),
              title: Text('Export Library', style: textTheme.bodyLarge),
              subtitle: Text('Save your library data to a file', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              onTap: () => _exportLibrary(context),
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
              onTap: () {
                HapticFeedback.lightImpact();
                _launchUrl(_privacyPolicyUrl);
              },
            ),
            ListTile(
              leading: Icon(Icons.description_outlined, color: colorScheme.onSurfaceVariant),
              title: Text('Terms of Service', style: textTheme.bodyLarge),
              onTap: () {
                HapticFeedback.lightImpact();
                _launchUrl(_termsOfServiceUrl);
              },
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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