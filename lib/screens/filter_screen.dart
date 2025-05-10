import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import 'details_screen.dart';

class FilterScreen extends StatefulWidget {
  final bool isMovie;

  const FilterScreen({Key? key, required this.isMovie}) : super(key: key);

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final TmdbService _tmdbService = TmdbService();
  String _selectedMood = '';
  final Set<String> _selectedGenres = {};

  final List<String> _moods = ['Happy', 'Thrilled', 'Chill', 'Sad'];

  // Define genre preferences by mood
  final Map<String, List<String>> _moodGenrePreferences = {
    'Happy': ['Comedy', 'Family', 'Adventure'],
    'Thrilled': ['Action', 'Thriller'],
    'Chill': ['Comedy'],
    'Sad': ['Drama', 'Romance', 'History', 'War'],
  };

  final Map<String, int> _movieGenres = {
    'Action': 28,
    'Adventure': 12,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Family': 10751,
    'Fantasy': 14,
    'History': 36,
    'Horror': 27,
    'Music': 10402,
    'Mystery': 9648,
    'Romance': 10749,
    'Sci-Fi': 878,
    'Thriller': 53,
    'War': 10752,
    'Western': 37,
  };

  final Map<String, int> _tvGenres = {
    'Action & Adventure': 10759,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Family': 10751,
    'History': 36,
    'Kids': 10762,
    'Mystery': 9648,
    'News': 10763,
    'Reality': 10764,
    'Sci-Fi & Fantasy': 10765,
    'Soap': 10766,
    'Talk': 10767,
    'War & Politics': 10768,
    'Western': 37,
  };

  Map<String, int> get _genres => widget.isMovie ? _movieGenres : _tvGenres;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMovie ? 'Movie Deal' : 'TV Deal', style: TextStyle(color: Colors.blue.shade100),),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Mood Selection
            Wrap(
              spacing: 8,
              children: _moods.map((mood) {
                return ChoiceChip(
                  label: Text(mood,
                      style: TextStyle(color: Colors.white)),
                  selected: _selectedMood == mood,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMood = selected ? mood : '';
                      // Auto-select genres based on mood if a mood is selected
                      _updateGenresBasedOnMood();
                    });
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.red,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Text(
              'Select genres:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Genre Selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genres.keys.map((genre) {
                return FilterChip(
                  label: Text(genre,
                      style: TextStyle(color: Colors.white)),
                  selected: _selectedGenres.contains(genre),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[800],
                  selectedColor: Colors.red[700],
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),

            const Spacer(),

            // Get My Deal Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _getRecommendations,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get My Deal!',
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to update genres based on selected mood
  void _updateGenresBasedOnMood() {
    if (_selectedMood.isEmpty) {
      // If no mood selected, don't change the genres
      return;
    }

    // Get preferred genres for this mood
    final preferredGenres = _moodGenrePreferences[_selectedMood] ?? [];

    // Clear current selections
    _selectedGenres.clear();

    // Add each preferred genre that exists in our genre map
    for (var genre in preferredGenres) {
      // For TV shows, we need to map some genres differently
      if (!widget.isMovie) {
        if (genre == 'Action') genre = 'Action & Adventure';
        if (genre == 'Sci-Fi') genre = 'Sci-Fi & Fantasy';
        if (genre == 'War') genre = 'War & Politics';
      }

      // Only add if the genre exists in our map
      if (_genres.containsKey(genre)) {
        _selectedGenres.add(genre);
      }
    }
  }

  void _getRecommendations() async {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one genre')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Convert selected genres to their ID values
      List<int> genreIds = _selectedGenres
          .map((genre) => _genres[genre]!)
          .toList();

      // Get recommendations based on genres
      List<MediaItem> recommendations = widget.isMovie
          ? await _tmdbService.getMovieRecommendations(genreIds)
          : await _tmdbService.getTVRecommendations(genreIds);

      // Apply mood-based sorting/filtering if a mood is selected
      if (_selectedMood.isNotEmpty) {
        recommendations = _applyMoodBasedSorting(recommendations);
      }

      // Close loading dialog
      Navigator.pop(context);

      if (recommendations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recommendations found')),
        );
        return;
      }

      // Show results in a bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Based on your ${_selectedMood.isNotEmpty ? "$_selectedMood mood and " : ""}preferences',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        final item = recommendations[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.posterUrl,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 50,
                                    height: 75,
                                    color: Colors.white,
                                    child: const Icon(Icons.error),
                                  ),
                            ),
                          ),
                          title: Text(item.title,
                              style: TextStyle(color: Colors.blue.shade100)),
                          subtitle: Text('Rating: ${item.rating}',
                              style: TextStyle(color: Colors.amberAccent)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailsScreen(item: item),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to sort/filter recommendations based on mood
  List<MediaItem> _applyMoodBasedSorting(List<MediaItem> recommendations) {
    switch (_selectedMood) {
      case 'Happy':
      // For happy mood, prioritize high-rated comedies and family content
        return recommendations
          ..sort((a, b) {
            // Sort by rating first for happy films (higher ratings first)
            if (a.rating != b.rating) return b.rating.compareTo(a.rating);

            // Then give preference to comedy/family genre items
            final aIsComedy = a.genres.contains('Comedy') || a.genres.contains('Family');
            final bIsComedy = b.genres.contains('Comedy') || b.genres.contains('Family');

            if (aIsComedy && !bIsComedy) return -1;
            if (!aIsComedy && bIsComedy) return 1;

            return 0;
          });
      case 'Thrilled':
      // For thrilled mood, prioritize action, thriller content
        return recommendations
          ..sort((a, b) {
            final aIsThrilling = a.genres.contains('Action') ||
                a.genres.contains('Thriller') ||
                a.genres.contains('Action & Adventure');
            final bIsThrilling = b.genres.contains('Action') ||
                b.genres.contains('Thriller') ||
                b.genres.contains('Action & Adventure');

            if (aIsThrilling && !bIsThrilling) return -1;
            if (!aIsThrilling && bIsThrilling) return 1;

            // Then prefer higher rated content
            return b.rating.compareTo(a.rating);
          });
      case 'Chill':
      // For chill mood, prioritize easy-going content
        return recommendations
          ..sort((a, b) {
            final aIsChill = a.genres.contains('Comedy') ||
                a.genres.contains('Documentary') ||
                a.genres.contains('Animation');
            final bIsChill = b.genres.contains('Comedy') ||
                b.genres.contains('Documentary') ||
                b.genres.contains('Animation');

            if (aIsChill && !bIsChill) return -1;
            if (!aIsChill && bIsChill) return 1;

            return 0;
          });
      case 'Sad':
      // For sad mood, prioritize dramas and emotional content
        return recommendations
          ..sort((a, b) {
            final aIsSad = a.genres.contains('Drama') ||
                a.genres.contains('Romance');
            final bIsSad = b.genres.contains('Drama') ||
                b.genres.contains('Romance');

            if (aIsSad && !bIsSad) return -1;
            if (!aIsSad && bIsSad) return 1;

            return 0;
          });
      default:
        return recommendations;
    }
  }
}