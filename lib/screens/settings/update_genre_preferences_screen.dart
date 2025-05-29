import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tmdb_service.dart';

class UpdateGenrePreferencesScreen extends StatefulWidget {
  const UpdateGenrePreferencesScreen({Key? key}) : super(key: key);

  @override
  State<UpdateGenrePreferencesScreen> createState() => _UpdateGenrePreferencesScreenState();
}

class _UpdateGenrePreferencesScreenState extends State<UpdateGenrePreferencesScreen> {
  final TmdbService _tmdbService = TmdbService();
  final Set<int> _selectedMovieGenreIds = {};
  final Set<int> _selectedTvGenreIds = {};

  late Map<int, String> _movieGenres;
  late Map<int, String> _tvGenres;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenresAndSavedPreferences();
  }

  Future<void> _loadGenresAndSavedPreferences() async {
    _movieGenres = _tmdbService.movieGenres;
    _tvGenres = _tmdbService.tvGenres;

    final prefs = await SharedPreferences.getInstance();
    final savedMovieGenreIds = prefs.getStringList('favoriteMovieGenreIds');
    final savedTvGenreIds = prefs.getStringList('favoriteTvGenreIds');

    if (savedMovieGenreIds != null) {
      _selectedMovieGenreIds.addAll(savedMovieGenreIds.map(int.parse));
    }
    if (savedTvGenreIds != null) {
      _selectedTvGenreIds.addAll(savedTvGenreIds.map(int.parse));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Corrected line for movie genres:
    await prefs.setStringList('favoriteMovieGenreIds', _selectedMovieGenreIds.map((id) => id.toString()).toList());

    // Corrected line for TV genres:
    await prefs.setStringList('favoriteTvGenreIds', _selectedTvGenreIds.map((id) => id.toString()).toList());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Genre preferences updated!',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
      );
      Navigator.pop(context); // Go back to SettingsScreen
    }
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
        title: const Text('Update Genres'),
        // Back button is implicitly available
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movie Genres',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, runSpacing: 4.0,
              children: _movieGenres.entries.map((entry) {
                final genreId = entry.key; final genreName = entry.value;
                final isSelected = _selectedMovieGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName), selected: isSelected,
                  onSelected: (bool selected) { setState(() { if (selected) { _selectedMovieGenreIds.add(genreId); } else { _selectedMovieGenreIds.remove(genreId); }}); },
                  labelStyle: TextStyle(color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'TV Show Genres',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, runSpacing: 4.0,
              children: _tvGenres.entries.map((entry) {
                final genreId = entry.key; final genreName = entry.value;
                final isSelected = _selectedTvGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName), selected: isSelected,
                  onSelected: (bool selected) { setState(() { if (selected) { _selectedTvGenreIds.add(genreId); } else { _selectedTvGenreIds.remove(genreId); }}); },
                  labelStyle: TextStyle(color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.onSecondaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: FilledButton(
                onPressed: (_selectedMovieGenreIds.isNotEmpty || _selectedTvGenreIds.isNotEmpty)
                    ? _savePreferences
                    : null,
                child: const Text('Update Genres'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}