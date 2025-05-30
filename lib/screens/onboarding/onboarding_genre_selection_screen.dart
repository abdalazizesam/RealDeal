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
        title: Text('Select Your Favorite Genres', style: textTheme.titleLarge), // M3 typography
        // backgroundColor: Colors.black, // Themed
        automaticallyImplyLeading: false, // No back button for linear onboarding
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movie Genres',
              style: textTheme.titleMedium, // M3 typography
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, runSpacing: 8.0, // Adjusted runSpacing
              children: _movieGenres.entries.map((entry) {
                final genreId = entry.key; final genreName = entry.value;
                final isSelected = _selectedMovieGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName),
                  selected: isSelected,
                  onSelected: (bool selected) { setState(() { if (selected) { _selectedMovieGenreIds.add(genreId); } else { _selectedMovieGenreIds.remove(genreId); }}); },
                  labelStyle: TextStyle(color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // M3 standard
                  selectedColor: colorScheme.secondaryContainer, // M3 selection color
                  checkmarkColor: colorScheme.onSecondaryContainer, // M3 checkmark color
                  showCheckmark: true, // Explicitly show checkmark
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'TV Show Genres',
              style: textTheme.titleMedium, // M3 typography
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, runSpacing: 8.0, // Adjusted runSpacing
              children: _tvGenres.entries.map((entry) {
                final genreId = entry.key; final genreName = entry.value;
                final isSelected = _selectedTvGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName),
                  selected: isSelected,
                  onSelected: (bool selected) { setState(() { if (selected) { _selectedTvGenreIds.add(genreId); } else { _selectedTvGenreIds.remove(genreId); }}); },
                  labelStyle: TextStyle(color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                  showCheckmark: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: FilledButton( // M3 FilledButton
                onPressed: (_selectedMovieGenreIds.isNotEmpty || _selectedTvGenreIds.isNotEmpty)
                    ? _saveAndProceed
                    : null,
                style: FilledButton.styleFrom(
                  // backgroundColor and foregroundColor will be themed
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: textTheme.labelLarge?.copyWith(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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