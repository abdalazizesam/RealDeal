// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'models/app_theme_preset.dart'; // Make sure this is imported for AppThemeMode and AppColorPalette

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LibraryProvider(prefs)),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: ReelDealAppLoader(showOnboarding: !hasCompletedOnboarding),
    ),
  );
}

class ReelDealAppLoader extends StatelessWidget {
  final bool showOnboarding;
  const ReelDealAppLoader({Key? key, required this.showOnboarding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We now use both consumer and listen to theme changes for MaterialApp
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ReelDealApp(
          showOnboarding: showOnboarding,
          selectedColorPalette: themeProvider.selectedColorPalette,
          selectedThemeMode: themeProvider.selectedThemeMode,
          isOledBlack: themeProvider.isOledBlack,
        );
      },
    );
  }
}

class ReelDealApp extends StatelessWidget {
  final bool showOnboarding;
  final AppColorPalette selectedColorPalette;
  final AppThemeMode selectedThemeMode;
  final bool isOledBlack;

  const ReelDealApp({
    Key? key,
    this.showOnboarding = false,
    required this.selectedColorPalette,
    required this.selectedThemeMode,
    required this.isOledBlack,
  }) : super(key: key);

  // Helper to determine the effective brightness
  Brightness _getEffectiveBrightness(BuildContext context) {
    if (selectedThemeMode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return selectedThemeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  // Helper to determine explicit background/surface colors for OLED black
  Color? _getExplicitBackgroundColor(BuildContext context) {
    final Brightness brightness = _getEffectiveBrightness(context);
    return isOledBlack && brightness == Brightness.dark ? Colors.black : null;
  }

  Color? _getExplicitSurfaceColor(BuildContext context) {
    final Brightness brightness = _getEffectiveBrightness(context);
    return isOledBlack && brightness == Brightness.dark ? const Color(0xFF121212) : null;
  }

  @override
  Widget build(BuildContext context) {
    final Brightness effectiveBrightness = _getEffectiveBrightness(context);
    final Color? explicitBackgroundColor = _getExplicitBackgroundColor(context);
    final Color? explicitSurfaceColor = _getExplicitSurfaceColor(context);

    final ColorScheme appColorScheme = ColorScheme.fromSeed(
      seedColor: selectedColorPalette.seedColor,
      brightness: effectiveBrightness,
      background: explicitBackgroundColor,
      surface: explicitSurfaceColor,
    );

    final Color scaffoldBgColor = explicitBackgroundColor ?? appColorScheme.background;
    final Color appBarBgColor = explicitSurfaceColor ?? appColorScheme.surface; // AppBar uses surface by default
    final Color cardBgColor = appColorScheme.surfaceContainerLow;
    final Color dialogBgColor = appColorScheme.surfaceContainerHigh;
    final Color bottomNavBgColor = appColorScheme.surfaceContainer;


    TextTheme baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'ReelDeal',
      // Pass the effective brightness for theming.
      themeMode: selectedThemeMode == AppThemeMode.system ? ThemeMode.system : (selectedThemeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: appColorScheme,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: scaffoldBgColor,

        textTheme: baseTextTheme.apply(
          bodyColor: appColorScheme.onSurface,
          displayColor: appColorScheme.onBackground,
        ).copyWith(
          titleLarge: baseTextTheme.titleLarge?.copyWith(
              color: appColorScheme.onBackground, fontWeight: FontWeight.bold),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
              color: appColorScheme.onSurfaceVariant),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
              color: appColorScheme.onBackground, fontWeight: FontWeight.bold),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
              color: appColorScheme.onSurface, height: 1.5),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
              color: appColorScheme.onSurface, height: 1.5),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
              color: appColorScheme.onPrimary, fontWeight: FontWeight.bold),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
              color: appColorScheme.onSurfaceVariant),
          titleSmall: baseTextTheme.titleSmall?.copyWith(
              color: appColorScheme.onSurface, fontWeight: FontWeight.w600),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: appBarBgColor,
          elevation: 0,
          titleTextStyle: TextStyle(color: appColorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w500),
          iconTheme: IconThemeData(color: appColorScheme.onSurfaceVariant),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: bottomNavBgColor,
          selectedItemColor: appColorScheme.onSurface,
          unselectedItemColor: appColorScheme.onSurfaceVariant,
          selectedIconTheme: IconThemeData(color: appColorScheme.primary),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          elevation: effectiveBrightness == Brightness.dark ? 1.0 : 2.0, // Increased to 2.0 for light theme
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: cardBgColor,
          shadowColor: appColorScheme.shadow.withOpacity(0.3),
          surfaceTintColor: Colors.transparent,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: appColorScheme.surfaceContainerHighest,
          selectedColor: appColorScheme.secondaryContainer,
          labelStyle: TextStyle(color: appColorScheme.onSurfaceVariant),
          secondaryLabelStyle: TextStyle(color: appColorScheme.onSecondaryContainer),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          side: BorderSide.none,
          iconTheme: IconThemeData(color: appColorScheme.onSurfaceVariant, size: 18),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
          titleTextStyle: TextStyle(color: appColorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w500),
          contentTextStyle: TextStyle(color: appColorScheme.onSurfaceVariant, fontSize: 16),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: appColorScheme.primary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: appColorScheme.onPrimary,
            backgroundColor: appColorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: baseTextTheme.labelLarge?.copyWith(color: appColorScheme.onPrimary, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: appColorScheme.surfaceContainerLow,
              foregroundColor: appColorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: baseTextTheme.labelLarge?.copyWith(color: appColorScheme.primary, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              elevation: 1,
            )
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: showOnboarding ? const OnboardingWelcomeScreen() : const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            activeIcon: Icon(Icons.menu_book),
            label: 'My Library',
          ),
        ],
      ),
    );
  }
}