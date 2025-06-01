import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tmdb_service.dart';
import 'onboarding_movie_selection_screen.dart';

class OnboardingGenreSelectionScreen extends StatefulWidget {
  const OnboardingGenreSelectionScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingGenreSelectionScreen> createState() => _OnboardingGenreSelectionScreenState();
}

class _OnboardingGenreSelectionScreenState extends State<OnboardingGenreSelectionScreen> {
  final TmdbService _tmdbService = TmdbService();
  final Set<int> _selectedMovieGenreIds = {};
  final Set<int> _selectedTvGenreIds = {};

  late Map<int, String> _movieGenres;
  late Map<int, String> _tvGenres;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    _movieGenres = _tmdbService.movieGenres;
    _tvGenres = _tmdbService.tvGenres;
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndProceed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteMovieGenreIds', _selectedMovieGenreIds.map((id) => id.toString()).toList());
    await prefs.setStringList('favoriteTvGenreIds', _selectedTvGenreIds.map((id) => id.toString()).toList());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingMovieSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Favorite Genres', style: textTheme.headlineSmall), // Slightly smaller for AppBar title
        centerTitle: true, // Center the title for a cleaner look
        automaticallyImplyLeading: false, // No back button for linear onboarding
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Increased overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us tailor recommendations just for you!',
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Movie Genres Section
            Text(
              'Movie Genres',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12), // Increased spacing
            Wrap(
              spacing: 10.0, // Adjusted spacing between chips
              runSpacing: 10.0, // Adjusted runSpacing between rows of chips
              children: _movieGenres.entries.map((entry) {
                final genreId = entry.key;
                final genreName = entry.value;
                final isSelected = _selectedMovieGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedMovieGenreIds.add(genreId);
                      } else {
                        _selectedMovieGenreIds.remove(genreId);
                      }
                    });
                  },
                  labelStyle: textTheme.labelLarge?.copyWith( // Use labelLarge for chip text
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // More rounded corners for chips
                    side: isSelected ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant), // Border for unselected
                  ),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  showCheckmark: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding inside chips
                );
              }).toList(),
            ),
            const SizedBox(height: 32), // Increased spacing between sections

            // TV Show Genres Section
            Text(
              'TV Show Genres',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: _tvGenres.entries.map((entry) {
                final genreId = entry.key;
                final genreName = entry.value;
                final isSelected = _selectedTvGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedTvGenreIds.add(genreId);
                      } else {
                        _selectedTvGenreIds.remove(genreId);
                      }
                    });
                  },
                  labelStyle: textTheme.labelLarge?.copyWith(
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: isSelected ? BorderSide.none : BorderSide(color: colorScheme.outlineVariant),
                  ),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  showCheckmark: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                );
              }).toList(),
            ),
            const SizedBox(height: 40), // Increased spacing before button
            Center(
              child: FilledButton(
                onPressed: (_selectedMovieGenreIds.isNotEmpty || _selectedTvGenreIds.isNotEmpty)
                    ? _saveAndProceed
                    : null, // Disable if no genres selected
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  textStyle: textTheme.labelLarge?.copyWith(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}