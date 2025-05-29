import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';
import 'screens/onboarding/onboarding_welcome_screen.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'models/app_theme_preset.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LibraryProvider(prefs)), // Changed to LibraryProvider
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ReelDealApp(
          showOnboarding: showOnboarding,
          currentThemePreset: themeProvider.currentTheme, // Pass the whole preset
        );
      },
    );
  }
}

class ReelDealApp extends StatelessWidget {
  final bool showOnboarding;
  final AppThemePreset currentThemePreset;

  const ReelDealApp({
    Key? key,
    this.showOnboarding = false,
    required this.currentThemePreset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme appColorScheme = ColorScheme.fromSeed(
      seedColor: currentThemePreset.seedColor,
      brightness: currentThemePreset.brightness,
      background: currentThemePreset.explicitBackgroundColor,
      surface: currentThemePreset.explicitSurfaceColor,
    );

    final Color scaffoldBgColor = currentThemePreset.explicitBackgroundColor ?? appColorScheme.background;
    final Color cardBgColor = currentThemePreset.explicitSurfaceColor ?? appColorScheme.surfaceContainerLow;
    final Color dialogBgColor = currentThemePreset.explicitSurfaceColor ?? appColorScheme.surfaceContainerHigh;
    final Color bottomNavBgColor = currentThemePreset.explicitSurfaceColor ?? appColorScheme.surfaceContainer;
    final Color appBarBgColor = currentThemePreset.explicitSurfaceColor ?? appColorScheme.surface;

    TextTheme baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'ReelDeal',
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
          elevation: currentThemePreset.brightness == Brightness.dark ? 1.0 : 1.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          color: cardBgColor,
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
    const LibraryScreen(), // Changed from WatchlistScreen
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
            icon: Icon(Icons.menu_book_rounded), // Changed icon to a book
            activeIcon: Icon(Icons.menu_book),
            label: 'My Library', // Changed label
          ),
        ],
      ),
    );
  }
}