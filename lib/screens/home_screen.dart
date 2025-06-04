// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:math' show Random, min;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../screens/filter_screen.dart';
import '../screens/details_screen.dart';
import '../screens/offline_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/error_display_widget.dart'; // Import the new widget

// New: Enum for media types to simplify category handling
enum MediaType { movie, tv }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TmdbService tmdbService = TmdbService();
  bool _isOffline = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  late TabController _tabController;

  MapEntry<String, List<MediaItem>>? _likedMovieRecommendation;
  MapEntry<String, List<MediaItem>>? _likedTvShowRecommendation;
  bool _isLoadingLikedRecommendations = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkConnectivity();
    _setupConnectivityListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLikedRecommendations();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityHelper.isConnected();
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = ConnectivityHelper.connectivityStream.listen((result) {
      if (mounted) {
        setState(() {
          _isOffline = result == ConnectivityResult.none;
        });
        if (!_isOffline) {
          _loadLikedRecommendations();
        }
      }
    });
  }

  Future<void> _loadLikedRecommendations() async {
    if (_isOffline) return;
    setState(() {
      _isLoadingLikedRecommendations = true;
      _likedMovieRecommendation = null;
      _likedTvShowRecommendation = null;
    });

    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    final List<MediaItem> completedItems = libraryProvider.getItemsByStatus(LibraryStatus.completed);

    final List<MediaItem> highlyRatedMovies = completedItems.where((item) => item.isMovie && (item.userRating ?? 0.0) >= 8.0).toList();
    final List<MediaItem> highlyRatedTvShows = completedItems.where((item) => !item.isMovie && (item.userRating ?? 0.0) >= 8.0).toList();

    final random = Random();

    if (highlyRatedMovies.isNotEmpty) {
      final MediaItem selectedLikedMovie = highlyRatedMovies[random.nextInt(highlyRatedMovies.length)];
      try {
        final List<MediaItem> similarMovies = await tmdbService.getSimilarMovies(selectedLikedMovie.id);
        final List<MediaItem> filteredSimilarMovies = similarMovies.where((s) => s.id != selectedLikedMovie.id).take(7).toList();
        if (filteredSimilarMovies.isNotEmpty) {
          _likedMovieRecommendation = MapEntry(selectedLikedMovie.title, filteredSimilarMovies);
        }
      } catch (e) {
        print('Error fetching similar movies for ${selectedLikedMovie.title}: $e');
        // Handle specific error for this section if needed
      }
    }

    if (highlyRatedTvShows.isNotEmpty) {
      final MediaItem selectedLikedTvShow = highlyRatedTvShows[random.nextInt(highlyRatedTvShows.length)];
      try {
        final List<MediaItem> similarTvShows = await tmdbService.getSimilarTVShows(selectedLikedTvShow.id);
        final List<MediaItem> filteredSimilarTvShows = similarTvShows.where((s) => s.id != selectedLikedTvShow.id).take(7).toList();
        if (filteredSimilarTvShows.isNotEmpty) {
          _likedTvShowRecommendation = MapEntry(selectedLikedTvShow.title, filteredSimilarTvShows);
        }
      } catch (e) {
        print('Error fetching similar TV shows for ${selectedLikedTvShow.title}: $e');
        // Handle specific error for this section if needed
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingLikedRecommendations = false;
      });
    }
  }

  Future<void> _getRandomMediaItem(BuildContext context, {required bool isMovie}) async {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      List<MediaItem> potentialPicks = [];
      List<int> preferredGenreIds = [];

      List<String>? genreIdStrings;
      if (isMovie) {
        genreIdStrings = prefs.getStringList('favoriteMovieGenreIds');
      } else {
        genreIdStrings = prefs.getStringList('favoriteTvGenreIds');
      }
      if (genreIdStrings != null && genreIdStrings.isNotEmpty) {
        preferredGenreIds = genreIdStrings.map((id) => int.parse(id)).toList();
      }

      if (preferredGenreIds.isNotEmpty) {
        try {
          if (isMovie) {
            potentialPicks.addAll(await tmdbService.getMovieRecommendations(preferredGenreIds, page: 1));
            potentialPicks.addAll(await tmdbService.getMovieRecommendations(preferredGenreIds, page: 2));
            potentialPicks.addAll(await tmdbService.getMovieRecommendations(preferredGenreIds, page: 3));
          } else {
            potentialPicks.addAll(await tmdbService.getTVRecommendations(preferredGenreIds, page: 1));
            potentialPicks.addAll(await tmdbService.getTVRecommendations(preferredGenreIds, page: 2));
            potentialPicks.addAll(await tmdbService.getTVRecommendations(preferredGenreIds, page: 3));
          }
        } catch (e) {
          print('Error fetching preferred genre recommendations: $e');
        }
      }

      List<MediaItem> generalPicks = [];
      try {
        if (isMovie) {
          generalPicks.addAll(await tmdbService.getPopularMovies());
          generalPicks.addAll(await tmdbService.getTopRatedMovies(page: Random().nextInt(3) + 1));
        } else {
          generalPicks.addAll(await tmdbService.getPopularTVShows());
          generalPicks.addAll(await tmdbService.getTopRatedTVShows(page: Random().nextInt(3) + 1));
        }
      } catch (e) {
        print('Error fetching general popular/top-rated items: $e');
      }

      final Set<int> seenIds = {};
      final List<MediaItem> combinedPicks = [];

      for (var item in potentialPicks) {
        if (seenIds.add(item.id)) {
          combinedPicks.add(item);
        }
      }
      for (var item in generalPicks) {
        if (seenIds.add(item.id)) {
          combinedPicks.add(item);
        }
      }

      final List<MediaItem> finalSelectionPool = [];
      for (final item in combinedPicks) {
        finalSelectionPool.add(item);
        final genreMaps = isMovie ? tmdbService.movieGenres : tmdbService.tvGenres;
        final matchingGenreId = item.genres.firstWhere(
                (genreName) => preferredGenreIds.contains(genreMaps.entries
                .firstWhere((e) => e.value == genreName, orElse: () => const MapEntry(-1, ''))
                .key),
            orElse: () => '');

        if (matchingGenreId.isNotEmpty) {
          finalSelectionPool.add(item);
        }
        if (item.rating >= 7.5) {
          finalSelectionPool.add(item);
        }
      }

      if (mounted) Navigator.pop(context);

      if (finalSelectionPool.isNotEmpty) {
        final random = Random();
        final randomMediaItem = finalSelectionPool[random.nextInt(finalSelectionPool.length)];
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(item: randomMediaItem),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not find a random ${isMovie ? "movie" : "TV show"} to suggest. Try again later!')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting random pick: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildCategoryButtonsSection({required BuildContext context, required MediaType mediaType}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isMovie = mediaType == MediaType.movie;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FilterScreen(isMovie: isMovie),
                  ),
                );
              },
              icon: Icon(isMovie ? Icons.movie : Icons.tv, size: 36),
              label: Text(
                isMovie ? 'Movie Deal' : 'TV Deal',
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _getRandomMediaItem(context, isMovie: isMovie),
              icon: Icon(isMovie ? Icons.shuffle_rounded : Icons.casino_rounded, size: 36),
              label: Text(
                isMovie ? 'Random Movie Pick!' : 'Random TV Pick!',
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCarouselSection({
    required BuildContext context,
    required String title,
    required Future<List<MediaItem>> Function() fetchMedia,
    String emptyMessage = 'No items found.', // New: customizable empty message
    String? errorMessageContext, // New: Context for error message
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<MediaItem>>(
            future: fetchMedia(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: colorScheme.primary));
              } else if (snapshot.hasError) {
                // Use the new ErrorDisplayWidget
                return ErrorDisplayWidget(
                  message: 'Failed to load ${errorMessageContext ?? title}. Please try again later.',
                  onRetry: () {
                    // Trigger a reload of the specific section.
                    // This is a simplified example; a more complex state management
                    // might expose a `reloadMedia` method for each section.
                    // For now, we trigger a full screen setState, which might
                    // refetch other sections too.
                    setState(() {});
                  },
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(emptyMessage, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)));
              }
              for (var i = 0; i < min(3, snapshot.data!.length); i++) {
                precacheImage(NetworkImage(snapshot.data![i].posterUrl), context);
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  final heroTag = '${title.replaceAll(' ', '_').toLowerCase()}_poster_${item.id}_${item.isMovie}';
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsScreen(item: item, heroTag: heroTag),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 1.0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      margin: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Hero(
                                tag: heroTag,
                                child: CachedNetworkImage(
                                  imageUrl: item.posterUrl,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                                    child: Icon(Icons.movie_creation_outlined, color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate()
                      .fadeIn(duration: 500.ms, delay: (50 * index).ms)
                      .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: (50 * index).ms, curve: Curves.easeOutCubic);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineScreen(
        onRetry: () {
          HapticFeedback.lightImpact();
          _checkConnectivity();
          // No need for setState here, _checkConnectivity will update _isOffline and trigger rebuild
        },
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reel Deal', style: textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: colorScheme.onSurfaceVariant),
            tooltip: 'Settings',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          onTap: (index) {
            HapticFeedback.lightImpact();
          },
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Movies Tab Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildCategoryButtonsSection(context: context, mediaType: MediaType.movie),
                if (_isLoadingLikedRecommendations)
                  Center(child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: colorScheme.primary)
                  ))
                else
                  if (_likedMovieRecommendation != null && _likedMovieRecommendation!.value.isNotEmpty)
                    _buildMediaCarouselSection(
                      context: context,
                      title: 'Because you liked "${_likedMovieRecommendation!.key}"',
                      fetchMedia: () async => _likedMovieRecommendation!.value,
                      emptyMessage: 'No similar movies found for your liked item.',
                      errorMessageContext: 'similar movies',
                    ),
                // Handle case where no liked movie recommendation could be fetched or found
                if(!_isLoadingLikedRecommendations && (_likedMovieRecommendation == null || _likedMovieRecommendation!.value.isEmpty))
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Because you liked movies...',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Center(
                          child: Text(
                            'Rate more movies in your library to get personalized recommendations here!',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                _buildMediaCarouselSection(
                  context: context,
                  title: 'Popular Movies Today',
                  fetchMedia: tmdbService.getPopularMovies,
                  emptyMessage: 'No popular movies found.',
                  errorMessageContext: 'popular movies',
                ),
                _buildMediaCarouselSection(
                  context: context,
                  title: 'Upcoming Movies',
                  fetchMedia: tmdbService.getUpcomingMovies,
                  emptyMessage: 'No upcoming movies found.',
                  errorMessageContext: 'upcoming movies',
                ),
                _buildMediaCarouselSection(
                  context: context,
                  title: 'Highest Rated Movies',
                  fetchMedia: tmdbService.getTopRatedMovies,
                  emptyMessage: 'No highly rated movies found.',
                  errorMessageContext: 'highest rated movies',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // TV Shows Tab Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildCategoryButtonsSection(context: context, mediaType: MediaType.tv),
                if (_isLoadingLikedRecommendations)
                  Center(child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: colorScheme.primary)
                  ))
                else
                  if (_likedTvShowRecommendation != null && _likedTvShowRecommendation!.value.isNotEmpty)
                    _buildMediaCarouselSection(
                      context: context,
                      title: 'Because you liked "${_likedTvShowRecommendation!.key}"',
                      fetchMedia: () async => _likedTvShowRecommendation!.value,
                      emptyMessage: 'No similar TV shows found for your liked item.',
                      errorMessageContext: 'similar TV shows',
                    ),
                // Handle case where no liked TV show recommendation could be fetched or found
                if(!_isLoadingLikedRecommendations && (_likedTvShowRecommendation == null || _likedTvShowRecommendation!.value.isEmpty))
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Because you liked TV Shows...',
                          style: textTheme.titleLarge,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                        child: Center(
                          child: Text(
                            'Rate more TV shows in your library to get personalized recommendations here!',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                _buildMediaCarouselSection(
                  context: context,
                  title: 'Popular TV Shows Today',
                  fetchMedia: tmdbService.getPopularTVShows,
                  emptyMessage: 'No popular TV shows found.',
                  errorMessageContext: 'popular TV shows',
                ),
                _buildMediaCarouselSection(
                  context: context,
                  title: 'Top Airing TV Shows',
                  fetchMedia: tmdbService.getTopAiringTVShows,
                  emptyMessage: 'No top airing TV shows found.',
                  errorMessageContext: 'top airing TV shows',
                ),
                _buildMediaCarouselSection(
                  context: context,
                  title: 'Highest Rated TV Shows',
                  fetchMedia: tmdbService.getTopRatedTVShows,
                  emptyMessage: 'No highly rated TV shows found.',
                  errorMessageContext: 'highest rated TV shows',
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}