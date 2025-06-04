import 'package:flutter/material.dart';
import 'onboarding_genre_selection_screen.dart';
import 'package:flutter/services.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use a larger, more prominent icon
              Icon(
                Icons.movie_filter_rounded,
                size: 96, // Slightly larger icon
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32), // Increased spacing
              Text(
                'Welcome to ReelDeal!',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Let\'s personalize your experience. Tell us a bit about your movie and TV show preferences.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48), // Increased spacing before button
              FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact(); // Haptic Feedback
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingGenreSelectionScreen()),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16), // Slightly more padding
                  textStyle: textTheme.labelLarge?.copyWith(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Slightly more rounded corners
                  ),
                  elevation: 2, // Add a subtle elevation for a Material 3 feel
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