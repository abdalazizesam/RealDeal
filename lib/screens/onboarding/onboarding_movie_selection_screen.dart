import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/media_item.dart'; //
import '../../services/tmdb_service.dart'; //
import '../../main.dart'; // To navigate to MainScreen

class OnboardingMovieSelectionScreen extends StatefulWidget {
  const OnboardingMovieSelectionScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingMovieSelectionScreen> createState() => _OnboardingMovieSelectionScreenState();
}

class _OnboardingMovieSelectionScreenState extends State<OnboardingMovieSelectionScreen> {
  final TmdbService _tmdbService = TmdbService();
  List<MediaItem> _topMovies = []; // Renamed for clarity
  List<MediaItem> _topTvShows = []; // Renamed for clarity
  final Set<int> _selectedMovieIds = {};
  final Set<int> _selectedTvShowIds = {};
  bool _isLoading = true;

  // Define how many items to select
  final int _minSelectionCount = 3;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() { // Ensure loading state is set at the beginning
      _isLoading = true;
    });
    try {
      // Fetch page 1 of top-rated movies and TV shows
      _topMovies = await _tmdbService.getTopRatedMovies(page: 1); // Use new method
      _topTvShows = await _tmdbService.getTopRatedTVShows(page: 1); // Use new method

      // Optional: If you want a larger selection, you could fetch more pages and combine them
      // For example:
      // final List<MediaItem> nextPageMovies = await _tmdbService.getTopRatedMovies(page: 2);
      // _topMovies.addAll(nextPageMovies);
      // Remove duplicates if fetching multiple pages, though usually not an issue with different pages
      // _topMovies = _topMovies.toSet().toList(); // Simple way to remove duplicates

    } catch (e) {
      print("Error loading top-rated media for onboarding: $e");
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recommendations. Please check your connection.')),
        );
      }
    }
    if (mounted) { // Check if the widget is still in the tree before calling setState
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedMovieIds.length + _selectedTvShowIds.length < _minSelectionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least $_minSelectionCount movies or TV shows in total to help us personalize your experience.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteMovieIds', _selectedMovieIds.map((id) => id.toString()).toList());
    await prefs.setStringList('favoriteTvShowIds', _selectedTvShowIds.map((id) => id.toString()).toList());
    await prefs.setBool('hasCompletedOnboarding', true);

    // Navigate to MainScreen and clear the onboarding route stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()), // Or ReelDealApp(showOnboarding: false) if you prefer
          (Route<dynamic> route) => false, // This predicate removes all previous routes
    );
  }

  Widget _buildMediaGrid(List<MediaItem> items, Set<int> selectedIds, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        items.isEmpty && !_isLoading
            ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: Text("Could not load $title.", style: TextStyle(color: Colors.white70, fontSize: 16))),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // To disable GridView's own scrolling
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3, // Common poster aspect ratio
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length > 12 ? 12 : items.length, // Limit to display, e.g., first 12 items
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = selectedIds.contains(item.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedIds.remove(item.id);
                  } else {
                    selectedIds.add(item.id);
                  }
                });
              },
              child: Card( // Using Card for a slightly elevated look and defined shape
                elevation: isSelected ? 8 : 2,
                color: Colors.grey[850],
                clipBehavior: Clip.antiAlias, // Ensures the image respects border radius
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isSelected
                      ? BorderSide(color: Colors.red, width: 3)
                      : BorderSide.none,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: Center(child: Icon(Icons.movie_creation_outlined, color: Colors.white54, size: 40)),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8), // Match card's border radius if not using Clip.antiAlias
                        ),
                        child: const Center(
                          child: Icon(Icons.check_circle, color: Colors.red, size: 50),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20), // Spacing after each grid
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Select Some Favorites', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button during onboarding
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // For button to take full width
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Tap on a few movies and TV shows you like (at least $_minSelectionCount in total). This will help us recommend content you\'ll love!',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85)),
                textAlign: TextAlign.center,
              ),
            ),
            _buildMediaGrid(_topMovies, _selectedMovieIds, 'Top Movies of All Time'),
            _buildMediaGrid(_topTvShows, _selectedTvShowIds, 'Top TV Shows of All Time'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Finish Setup', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20), // Some padding at the bottom
          ],
        ),
      ),
    );
  }
}