import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tmdb_service.dart'; // Assuming your TmdbService is here
import 'onboarding_movie_selection_screen.dart'; // We'll create this next

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
    // In TmdbService, movieGenres and tvGenres are public maps.
    // If they were private or fetched asynchronously, you'd call a method here.
    // For now, let's assume they are directly accessible or you have methods to get them.
    // If you need to fetch them:
    // _movieGenres = await _tmdbService.getMovieGenreMap();
    // _tvGenres = await _tmdbService.getTvGenreMap();
    // For this example, using the maps directly from the instance if public:
    _movieGenres = _tmdbService.movieGenres; //
    _tvGenres = _tmdbService.tvGenres; //
    setState(() {
      _isLoading = false;
    });
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Favorite Genres', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // No back button here
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movie Genres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _movieGenres.entries.map((entry) {
                final genreId = entry.key;
                final genreName = entry.value;
                final isSelected = _selectedMovieGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName, style: TextStyle(color: Colors.white)),
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
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.red,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'TV Show Genres',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _tvGenres.entries.map((entry) {
                final genreId = entry.key;
                final genreName = entry.value;
                final isSelected = _selectedTvGenreIds.contains(genreId);
                return FilterChip(
                  label: Text(genreName, style: TextStyle(color: Colors.white)),
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
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.red,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: (_selectedMovieGenreIds.isNotEmpty || _selectedTvGenreIds.isNotEmpty)
                    ? _saveAndProceed
                    : null, // Disable if no genres selected
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Next', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}