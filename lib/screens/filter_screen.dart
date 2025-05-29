import 'package:flutter/material.dart';
import 'dart:ui';
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

  final Map<String, List<String>> _moodGenrePreferences = {
    'Happy': ['Comedy', 'Family', 'Adventure'],
    'Thrilled': ['Action', 'Thriller'],
    'Chill': ['Comedy'],
    'Sad': ['Drama', 'Romance', 'History', 'War'],
  };

  final Map<String, int> _movieGenres = {
    'Action': 28, 'Adventure': 12, 'Animation': 16, 'Comedy': 35, 'Crime': 80,
    'Documentary': 99, 'Drama': 18, 'Family': 10751, 'Fantasy': 14, 'History': 36,
    'Horror': 27, 'Music': 10402, 'Mystery': 9648, 'Romance': 10749,
    'Sci-Fi': 878, 'Thriller': 53, 'War': 10752, 'Western': 37,
  };

  final Map<String, int> _tvGenres = {
    'Action & Adventure': 10759, 'Animation': 16, 'Comedy': 35, 'Crime': 80,
    'Documentary': 99, 'Drama': 18, 'Family': 10751, 'History': 36, 'Kids': 10762,
    'Mystery': 9648, 'News': 10763, 'Reality': 10764, 'Sci-Fi & Fantasy': 10765,
    'Soap': 10766, 'Talk': 10767, 'War & Politics': 10768, 'Western': 37,
  };

  Map<String, int> get _genres => widget.isMovie ? _movieGenres : _tvGenres;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isMovie ? 'Movie Deal' : 'TV Deal',
        ),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling today?',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMood = selected ? mood : '';
                      _updateGenresBasedOnMood();
                    });
                  },
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Select genres:',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genres.keys.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                  labelStyle: TextStyle(
                    color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _getRecommendations,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Get My Deal!',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _updateGenresBasedOnMood() {
    if (_selectedMood.isEmpty) {
      return;
    }
    final preferredGenres = _moodGenrePreferences[_selectedMood] ?? [];
    _selectedGenres.clear();
    for (var genre in preferredGenres) {
      if (!widget.isMovie) {
        if (genre == 'Action') genre = 'Action & Adventure';
        if (genre == 'Sci-Fi') genre = 'Sci-Fi & Fantasy';
        if (genre == 'War') genre = 'War & Politics';
      }
      if (_genres.containsKey(genre)) {
        _selectedGenres.add(genre);
      }
    }
  }

  void _getRecommendations() async {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one genre'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );

    try {
      List<int> genreIds = _selectedGenres.map((genre) => _genres[genre]!).toList();
      List<MediaItem> recommendations = widget.isMovie
          ? await _tmdbService.getMovieRecommendations(genreIds)
          : await _tmdbService.getTVRecommendations(genreIds);

      if (_selectedMood.isNotEmpty) {
        recommendations = _applyMoodBasedSorting(recommendations);
      }

      Navigator.pop(context);

      if (recommendations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No recommendations found for your selection.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      _showRecommendationsSheet(recommendations);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  void _showRecommendationsSheet(List<MediaItem> recommendations) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
            ),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    'Based on your ${_selectedMood.isNotEmpty ? "$_selectedMood mood and " : ""}preferences',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final item = recommendations[index];
                      final heroTag = 'filter_recommendation_${item.id}';
                      return ListTile(
                        leading: Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              item.posterUrl,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50, height: 75,
                                color: colorScheme.surfaceVariant,
                                child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                        title: Text(item.title, style: textTheme.titleSmall),
                        subtitle: Text(
                          'Rating: ${item.rating.toStringAsFixed(1)} - ${item.year}',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(item: item, heroTag: heroTag),
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
  }

  List<MediaItem> _applyMoodBasedSorting(List<MediaItem> recommendations) {
    switch (_selectedMood) {
      case 'Happy':
        return recommendations
          ..sort((a, b) {
            if (a.rating != b.rating) return b.rating.compareTo(a.rating);
            final aIsComedy = a.genres.contains('Comedy') || a.genres.contains('Family');
            final bIsComedy = b.genres.contains('Comedy') || b.genres.contains('Family');
            if (aIsComedy && !bIsComedy) return -1;
            if (!aIsComedy && bIsComedy) return 1;
            return 0;
          });
      case 'Thrilled':
        return recommendations
          ..sort((a, b) {
            final aIsThrilling = a.genres.contains('Action') || a.genres.contains('Thriller') || a.genres.contains('Action & Adventure');
            final bIsThrilling = b.genres.contains('Action') || b.genres.contains('Thriller') || b.genres.contains('Action & Adventure');
            if (aIsThrilling && !bIsThrilling) return -1;
            if (!aIsThrilling && bIsThrilling) return 1;
            return b.rating.compareTo(a.rating);
          });
      case 'Chill':
        return recommendations
          ..sort((a, b) {
            final aIsChill = a.genres.contains('Comedy') || a.genres.contains('Documentary') || a.genres.contains('Animation');
            final bIsChill = b.genres.contains('Comedy') || b.genres.contains('Documentary') || b.genres.contains('Animation');
            if (aIsChill && !bIsChill) return -1;
            if (!aIsChill && bIsChill) return 1;
            return 0;
          });
      case 'Sad':
        return recommendations
          ..sort((a, b) {
            final aIsSad = a.genres.contains('Drama') || a.genres.contains('Romance');
            final bIsSad = b.genres.contains('Drama') || b.genres.contains('Romance');
            if (aIsSad && !bIsSad) return -1;
            if (!aIsSad && bIsSad) return 1;
            return 0;
          });
      default:
        return recommendations;
    }
  }
}