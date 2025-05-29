import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/media_item.dart';
import '../../services/tmdb_service.dart';

class UpdateMediaPreferencesScreen extends StatefulWidget {
  const UpdateMediaPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<UpdateMediaPreferencesScreen> createState() => _UpdateMediaPreferencesScreenState();
}

class _UpdateMediaPreferencesScreenState extends State<UpdateMediaPreferencesScreen> {
  final TmdbService _tmdbService = TmdbService();
  List<MediaItem> _topMovies = [];
  List<MediaItem> _topTvShows = [];
  final Set<int> _selectedMovieIds = {};
  final Set<int> _selectedTvShowIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMediaAndSavedPreferences();
  }

  Future<void> _loadMediaAndSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMovieIds = prefs.getStringList('favoriteMovieIds');
    final savedTvShowIds = prefs.getStringList('favoriteTvShowIds');

    if (savedMovieIds != null) {
      _selectedMovieIds.addAll(savedMovieIds.map(int.parse));
    }
    if (savedTvShowIds != null) {
      _selectedTvShowIds.addAll(savedTvShowIds.map(int.parse));
    }

    try {
      _topMovies = await _tmdbService.getTopRatedMovies(page: 1);
      _topTvShows = await _tmdbService.getTopRatedTVShows(page: 1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load media: $e')),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteMovieIds', _selectedMovieIds.map((id) => id.toString()).toList());
    await prefs.setStringList('favoriteTvShowIds', _selectedTvShowIds.map((id) => id.toString()).toList());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Media preferences updated!',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildMediaGrid(List<MediaItem> items, Set<int> selectedIds, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length > 12 ? 12 : items.length,
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
              child: Card(
                elevation: isSelected ? 4 : 1,
                color: colorScheme.surfaceContainerLow,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isSelected
                      ? BorderSide(color: colorScheme.primary, width: 3)
                      : BorderSide.none,
                ),
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
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(Icons.check_circle, color: colorScheme.primary, size: 50),
                        ),
                      ),
                  ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Favorites'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Update your preferred movies and TV shows. This helps us personalize your recommendations.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
            _buildMediaGrid(_topMovies, _selectedMovieIds, 'Top Movies of All Time'),
            _buildMediaGrid(_topTvShows, _selectedTvShowIds, 'Top TV Shows of All Time'),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: _savePreferences,
              child: const Text('Update Favorites'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}