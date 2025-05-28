// home_screen.dart

import 'dart:async';
import 'dart:math' show Random, min; // Import min
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../screens/filter_screen.dart';
import '../screens/details_screen.dart';
import '../screens/offline_screen.dart';
import '../screens/search_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Assuming ConnectivityHelper is in offline_screen.dart or accessible
import 'offline_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key); //

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService tmdbService = TmdbService(); //
  bool _isOffline = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity(); //
    _setupConnectivityListener(); //
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityHelper.isConnected(); //
    if (mounted) {
      setState(() {
        _isOffline = !isConnected; //
      });
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        ConnectivityHelper.connectivityStream.listen((result) { //
          if (mounted) {
            setState(() {
              _isOffline = result == ConnectivityResult.none; //
            });
          }
        });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); //
    super.dispose();
  }

  Future<void> _getRandomMediaItem(BuildContext context, {required bool isMovie}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator(color: Colors.red));
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      List<MediaItem> potentialPicks = [];
      List<String>? genreIdStrings;
      List<int> genreIds = [];

      if (isMovie) {
        genreIdStrings = prefs.getStringList('favoriteMovieGenreIds');
      } else {
        genreIdStrings = prefs.getStringList('favoriteTvGenreIds');
      }

      if (genreIdStrings != null && genreIdStrings.isNotEmpty) {
        genreIds = genreIdStrings.map((id) => int.parse(id)).toList();
      }

      if (genreIds.isNotEmpty) {
        if (isMovie) {
          potentialPicks = await tmdbService.getMovieRecommendations(genreIds);
          if (potentialPicks.length < 10 && potentialPicks.isNotEmpty) { // Check if not empty before fetching more
            final nextPagePicks = await tmdbService.getMovieRecommendations(genreIds, page: 2);
            potentialPicks.addAll(nextPagePicks);
          }
        } else {
          potentialPicks = await tmdbService.getTVRecommendations(genreIds);
          if (potentialPicks.length < 10 && potentialPicks.isNotEmpty) { // Check if not empty
            final nextPagePicks = await tmdbService.getTVRecommendations(genreIds, page: 2);
            potentialPicks.addAll(nextPagePicks);
          }
        }
        if (potentialPicks.length > 20) {
          final ids = <int>{};
          potentialPicks.retainWhere((item) => ids.add(item.id));
        }
      }

      if (potentialPicks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No specific preferences found, picking from top rated ${isMovie ? "movies" : "TV shows"}!')),
        );
        if (isMovie) {
          potentialPicks = await tmdbService.getTopRatedMovies(page: Random().nextInt(5) + 1);
        } else {
          potentialPicks = await tmdbService.getTopRatedTVShows(page: Random().nextInt(5) + 1);
        }
      }

      Navigator.pop(context);

      if (potentialPicks.isNotEmpty) {
        final random = Random();
        final randomMediaItem = potentialPicks[random.nextInt(potentialPicks.length)];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(item: randomMediaItem),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find a random ${isMovie ? "movie" : "TV show"} to suggest. Try again later!')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting random pick: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineScreen( //
        onRetry: () {
          _checkConnectivity(); //
          setState(() {});
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reel Deal', style: TextStyle(color: Colors.white)), //
        backgroundColor: Colors.black, //
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white), //
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()), //
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), //
        child: Padding(
          padding: const EdgeInsets.all(16.0), //
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row( //
                children: [
                  Expanded(
                    child: _buildDealButton(
                      context,
                      'Movie Deal', //
                      Icons.movie, //
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const FilterScreen(isMovie: true), //
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), //
                  Expanded(
                    child: _buildDealButton(
                      context,
                      'TV Deal', //
                      Icons.tv, //
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const FilterScreen(isMovie: false), //
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24), //

              _buildRandomPickButton(
                context,
                'Random Movie Pick!',
                Icons.shuffle_rounded,
                    () => _getRandomMediaItem(context, isMovie: true),
                Colors.blueAccent,
              ),
              const SizedBox(height: 16), //
              _buildRandomPickButton(
                context,
                'Random TV Show Pick!',
                Icons.casino_rounded,
                    () => _getRandomMediaItem(context, isMovie: false),
                Colors.greenAccent,
              ),
              const SizedBox(height: 24), //


              const Text( //
                'Popular Movies Today', //
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), //
              ),
              const SizedBox(height: 8), //
              RefreshIndicator( //
                onRefresh: () async {
                  if (mounted) {
                    setState(() {});
                  }
                  return Future.value();
                },
                child: SizedBox(
                  height: 200, //
                  child: FutureBuilder<List<MediaItem>>(
                    future: tmdbService.getPopularMovies(), //
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) { //
                        return const Center( //
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasError) { //
                        return Text('Error: ${snapshot.error}'); //
                      } else if (!snapshot.hasData ||
                          snapshot.data!.isEmpty) { //
                        return const Text('No movies found'); //
                      }
                      for (var i = 0;
                      i < min(3, snapshot.data!.length); //
                      i++) {
                        precacheImage( //
                            NetworkImage(snapshot.data![i].posterUrl), //
                            context);
                      }
                      return _buildMediaList(context, snapshot.data!); //
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24), //

              const Text( //
                'Popular TV Shows Today', //
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), //
              ),
              const SizedBox(height: 8), //
              RefreshIndicator( //
                onRefresh: () async {
                  if (mounted) {
                    setState(() {});
                  }
                  return Future.value();
                },
                child: SizedBox(
                  height: 200, //
                  child: FutureBuilder<List<MediaItem>>(
                    future: tmdbService.getPopularTVShows(), //
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) { //
                        return const Center( //
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasError) { //
                        return Text('Error: ${snapshot.error}'); //
                      } else if (!snapshot.hasData ||
                          snapshot.data!.isEmpty) { //
                        return const Text('No TV shows found'); //
                      }
                      for (var i = 0;
                      i < min(3, snapshot.data!.length); //
                      i++) {
                        precacheImage( //
                            NetworkImage(snapshot.data![i].posterUrl), //
                            context);
                      }
                      return _buildMediaList(context, snapshot.data!); //
                    },
                  ),
                ),
              ),

              // New Section: Popular Movies of All Time
              const SizedBox(height: 24),
              const Text(
                'Popular Movies of All Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RefreshIndicator(
                onRefresh: () async {
                  if (mounted) {
                    setState(() {}); // This will cause FutureBuilders to rebuild
                  }
                  return Future.value();
                },
                child: SizedBox(
                  height: 200,
                  child: FutureBuilder<List<MediaItem>>(
                    future: tmdbService.getTopRatedMovies(), // Use the new service method
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No all-time popular movies found');
                      }
                      // Precache images for smoother scrolling
                      for (var i = 0; i < min(3, snapshot.data!.length); i++) {
                        precacheImage(NetworkImage(snapshot.data![i].posterUrl), context);
                      }
                      return _buildMediaList(context, snapshot.data!);
                    },
                  ),
                ),
              ),

              // New Section: Popular TV Shows of All Time
              const SizedBox(height: 24),
              const Text(
                'Popular TV Shows of All Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RefreshIndicator(
                onRefresh: () async {
                  if (mounted) {
                    setState(() {}); // This will cause FutureBuilders to rebuild
                  }
                  return Future.value();
                },
                child: SizedBox(
                  height: 200,
                  child: FutureBuilder<List<MediaItem>>(
                    future: tmdbService.getTopRatedTVShows(), // Use the new service method
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No all-time popular TV shows found');
                      }
                      // Precache images
                      for (var i = 0; i < min(3, snapshot.data!.length); i++) {
                        precacheImage(NetworkImage(snapshot.data![i].posterUrl), context);
                      }
                      return _buildMediaList(context, snapshot.data!);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealButton(
      BuildContext context,
      String text,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return ElevatedButton( //
      onPressed: onPressed, //
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20), //
        backgroundColor: Colors.red, //
        shape: RoundedRectangleBorder( //
          borderRadius: BorderRadius.circular(12), //
        ),
        foregroundColor: Colors.white,
      ),
      child: Column( //
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36), //
          const SizedBox(height: 8), //
          Text( //
            text, //
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), //
          ),
        ],
      ),
    );
  }

  Widget _buildRandomPickButton(
      BuildContext context,
      String text,
      IconData icon,
      VoidCallback onPressed,
      Color backgroundColor,
      ) {
    return SizedBox( //
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }


  Widget _buildMediaList(BuildContext context, List<MediaItem> items) {
    return ListView.builder( //
      scrollDirection: Axis.horizontal, //
      itemCount: items.length, //
      itemBuilder: (context, index) {
        final item = items[index]; //
        return GestureDetector( //
          onTap: () {
            Navigator.push( //
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(item: item), //
              ),
            );
          },
          child: Container( //
            width: 120, //
            margin: const EdgeInsets.only(right: 12), //
            child: Column( //
              crossAxisAlignment: CrossAxisAlignment.start, //
              children: [
                Expanded( //
                  child: ClipRRect( //
                    borderRadius: BorderRadius.circular(8), //
                    child: CachedNetworkImage( //
                      imageUrl: item.posterUrl, //
                      fit: BoxFit.cover, //
                      width: 120, //
                      placeholder: (context, url) => Container( //
                        color: Colors.grey[800], //
                        child: const Center( //
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent), //
                        ),
                      ),
                      errorWidget: (context, url, error) => Container( //
                        color: Colors.grey[800], //
                        child: const Icon(Icons.error, color: Colors.white54), //
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4), //
                Text( //
                  item.title, //
                  maxLines: 2, //
                  overflow: TextOverflow.ellipsis, //
                  style: const TextStyle(fontSize: 12, color: Colors.white), //
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}