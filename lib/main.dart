// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/watchlist_screen.dart';
import 'providers/watchlist_provider.dart';
// Import new onboarding welcome screen (we'll create this next)
import 'screens/onboarding/onboarding_welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Check if onboarding has been completed
  bool hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (context) => WatchlistProvider(prefs),
      child: ReelDealApp(showOnboarding: !hasCompletedOnboarding), // Pass the flag
    ),
  );
}

class ReelDealApp extends StatelessWidget {
  final bool showOnboarding; // Add this
  const ReelDealApp({Key? key, this.showOnboarding = false}) : super(key: key); // Modify constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReelDeal',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.black87,
        textTheme: const TextTheme( // Added const
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Conditionally set the home screen
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
    const WatchlistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Watchlist',
          ),
        ],
      ),
    );
  }
}