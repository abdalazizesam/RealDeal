import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/media_item.dart';
import '../../services/tmdb_service.dart';
import '../../main.dart'; // Assuming your main app is now 'MyApp' for Navigator.pushAndRemoveUntil
import 'package:provider/provider.dart';
import '../../providers/library_provider.dart';

class OnboardingMovieSelectionScreen extends StatefulWidget {
  const OnboardingMovieSelectionScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingMovieSelectionScreen> createState() => _OnboardingMovieSelectionScreenState();
}

class _OnboardingMovieSelectionScreenState extends State<OnboardingMovieSelectionScreen> {
  final TmdbService _tmdbService = TmdbService();
  List<MediaItem> _topMovies = [];
  List<MediaItem> _topTvShows = [];
  final Set<int> _selectedMovieIds = {};
  final Set<int> _selectedTvShowIds = {};
  bool _isLoading = true;

  final int _minSelectionCount = 3;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch more data to ensure a good selection pool
      final moviesPage1 = await _tmdbService.getTopRatedMovies(page: 1);
      final moviesPage2 = await _tmdbService.getTopRatedMovies(page: 2);
      final tvShowsPage1 = await _tmdbService.getTopRatedTVShows(page: 1);
      final tvShowsPage2 = await _tmdbService.getTopRatedTVShows(page: 2);

      _topMovies = [...moviesPage1, ...moviesPage2].toSet().toList(); // Deduplicate
      _topTvShows = [...tvShowsPage1, ...tvShowsPage2].toSet().toList(); // Deduplicate

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load recommendations. Please check your connection.')),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedMovieIds.length + _selectedTvShowIds.length < _minSelectionCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least $_minSelectionCount movies or TV shows in total to help us personalize your experience.',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteMovieIds', _selectedMovieIds.map((id) => id.toString()).toList());
    await prefs.setStringList('favoriteTvShowIds', _selectedTvShowIds.map((id) => id.toString()).toList());
    await prefs.setBool('hasCompletedOnboarding', true);

    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    // Add selected items to library as "completed" with a high rating
    for (int movieId in _selectedMovieIds) {
      MediaItem? movie;
      try {
        movie = _topMovies.firstWhere((item) => item.id == movieId);
      } catch (e) {
        print('Movie with ID $movieId not found in _topMovies: $e');
      }
      if (movie != null) {
        libraryProvider.updateItemStatus(movie, LibraryStatus.completed, userRating: 10.0, progress: 1);
      }
    }

    for (int tvShowId in _selectedTvShowIds) {
      MediaItem? tvShow;
      try {
        tvShow = _topTvShows.firstWhere((item) => item.id == tvShowId);
      } catch (e) {
        print('TV Show with ID $tvShowId not found in _topTvShows: $e');
      }
      if (tvShow != null) {
        libraryProvider.updateItemStatus(tvShow, LibraryStatus.completed, userRating: 10.0);
      }
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Widget _buildMediaGrid(List<MediaItem> items, Set<int> selectedIds, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0), // More vertical padding
          child: Text(
            title,
            style: textTheme.titleMedium,
          ),
        ),
        items.isEmpty && !_isLoading
            ? Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: Text("Could not load $title.", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2 / 3, // Standard aspect ratio for posters
            crossAxisSpacing: 12, // Increased spacing
            mainAxisSpacing: 12, // Increased spacing
          ),
          itemCount: items.length > 15 ? 15 : items.length, // Display a few more options up to 15
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
              child: AnimatedContainer( // Use AnimatedContainer for smooth transition
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Slightly more rounded corners
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    width: isSelected ? 3 : 0, // Border width changes on selection
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Clip image with slightly less radius than container
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: colorScheme.surfaceVariant,
                          child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.surfaceVariant,
                          child: Center(child: Icon(Icons.movie_creation_outlined, color: colorScheme.onSurfaceVariant, size: 40)),
                        ),
                      ),
                      // Overlay for selected state
                      if (isSelected)
                        Container(
                          color: colorScheme.primary.withOpacity(0.3), // Semi-transparent overlay
                          alignment: Alignment.center,
                          child: Icon(Icons.check_circle, color: colorScheme.onPrimary, size: 56), // Larger checkmark
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: colorScheme.primary)));
    }

    // Determine if the "Finish Setup" button should be enabled
    final bool canProceed = (_selectedMovieIds.length + _selectedTvShowIds.length) >= _minSelectionCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Some Favorites', style: textTheme.headlineSmall),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Increased overall padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0), // Increased bottom padding
              child: Text(
                'Tap on a few movies and TV shows you like (at least $_minSelectionCount in total). This will help us personalize your experience!',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            _buildMediaGrid(_topMovies, _selectedMovieIds, 'Top Movies of All Time'),
            _buildMediaGrid(_topTvShows, _selectedTvShowIds, 'Top TV Shows of All Time'),
            const SizedBox(height: 40), // Increased spacing before button
            FilledButton(
              onPressed: canProceed ? _completeOnboarding : null, // Enabled/disabled based on selection count
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: textTheme.labelLarge?.copyWith(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text('Finish Setup'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}