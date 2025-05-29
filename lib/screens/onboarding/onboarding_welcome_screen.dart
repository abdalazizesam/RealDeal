import 'package:flutter/material.dart';
import 'onboarding_genre_selection_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Use themed background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon( // Optional: Add an icon or logo for welcome
                Icons.movie_filter_rounded,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to ReelDeal!',
                style: textTheme.headlineMedium?.copyWith( // M3 typography
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s personalize your experience. Tell us a bit about your movie and TV show preferences.',
                style: textTheme.bodyLarge?.copyWith( // M3 typography
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              FilledButton( // M3 FilledButton
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingGenreSelectionScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  // backgroundColor and foregroundColor will be themed
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: textTheme.labelLarge?.copyWith(fontSize: 18), // M3 button text style
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // M3 standard radius
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}