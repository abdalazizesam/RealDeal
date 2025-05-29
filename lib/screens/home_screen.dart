import 'dart:async';
import 'dart:math' show Random, min; //
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; //
import 'package:shared_preferences/shared_preferences.dart'; //
import '../models/media_item.dart'; //
import '../services/tmdb_service.dart'; //
import '../screens/filter_screen.dart'; //
import '../screens/details_screen.dart'; //
import '../screens/offline_screen.dart'; //
import 'package:connectivity_plus/connectivity_plus.dart'; //
import 'package:flutter_animate/flutter_animate.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key); //

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> { //
  final TmdbService tmdbService = TmdbService(); //
  bool _isOffline = false; //
  late StreamSubscription<ConnectivityResult> _connectivitySubscription; //

  @override
  void initState() { //
    super.initState(); //
    _checkConnectivity(); //
    _setupConnectivityListener(); //
  }

  Future<void> _checkConnectivity() async { //
    final isConnected = await ConnectivityHelper.isConnected(); //
    if (mounted) { //
      setState(() { //
        _isOffline = !isConnected; //
      });
    }
  }

  void _setupConnectivityListener() { //
    _connectivitySubscription =
        ConnectivityHelper.connectivityStream.listen((result) { //
          if (mounted) { //
            setState(() { //
              _isOffline = result == ConnectivityResult.none; //
            });
          }
        });
  }

  @override
  void dispose() { //
    _connectivitySubscription.cancel(); //
    super.dispose(); //
  }

  Future<void> _getRandomMediaItem(BuildContext context, {required bool isMovie}) async { //
    showDialog( //
      context: context, //
      barrierDismissible: false, //
      builder: (BuildContext context) { //
        return const Center(child: CircularProgressIndicator(color: Colors.red)); //
      },
    );

    try { //
      final prefs = await SharedPreferences.getInstance(); //
      List<MediaItem> potentialPicks = []; //
      List<String>? genreIdStrings; //
      List<int> genreIds = []; //

      if (isMovie) { //
        genreIdStrings = prefs.getStringList('favoriteMovieGenreIds'); //
      } else {
        genreIdStrings = prefs.getStringList('favoriteTvGenreIds'); //
      }

      if (genreIdStrings != null && genreIdStrings.isNotEmpty) { //
        genreIds = genreIdStrings.map((id) => int.parse(id)).toList(); //
      }

      if (genreIds.isNotEmpty) { //
        if (isMovie) { //
          potentialPicks = await tmdbService.getMovieRecommendations(genreIds); //
          if (potentialPicks.length < 10 && potentialPicks.isNotEmpty) { //
            final nextPagePicks = await tmdbService.getMovieRecommendations(genreIds, page: 2); //
            potentialPicks.addAll(nextPagePicks); //
          }
        } else {
          potentialPicks = await tmdbService.getTVRecommendations(genreIds); //
          if (potentialPicks.length < 10 && potentialPicks.isNotEmpty) { //
            final nextPagePicks = await tmdbService.getTVRecommendations(genreIds, page: 2); //
            potentialPicks.addAll(nextPagePicks); //
          }
        }
        if (potentialPicks.length > 20) { //
          final ids = <int>{}; //
          potentialPicks.retainWhere((item) => ids.add(item.id)); //
        }
      }

      if (potentialPicks.isEmpty) { //
        ScaffoldMessenger.of(context).showSnackBar( //
          SnackBar(content: Text('No specific preferences found, picking from top rated ${isMovie ? "movies" : "TV shows"}!')), //
        );
        if (isMovie) { //
          potentialPicks = await tmdbService.getTopRatedMovies(page: Random().nextInt(5) + 1); //
        } else {
          potentialPicks = await tmdbService.getTopRatedTVShows(page: Random().nextInt(5) + 1); //
        }
      }

      Navigator.pop(context); //

      if (potentialPicks.isNotEmpty) { //
        final random = Random(); //
        final randomMediaItem = potentialPicks[random.nextInt(potentialPicks.length)]; //
        Navigator.push( //
          context, //
          MaterialPageRoute( //
            builder: (context) => DetailsScreen(item: randomMediaItem), //
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar( //
          SnackBar(content: Text('Could not find a random ${isMovie ? "movie" : "TV show"} to suggest. Try again later!')), //
        );
      }
    } catch (e) { //
      Navigator.pop(context); //
      ScaffoldMessenger.of(context).showSnackBar( //
        SnackBar(content: Text('Error getting random pick: ${e.toString()}')), //
      );
    }
  }


  Widget _buildDealButton( //
      BuildContext context, //
      String text, //
      IconData icon, //
      VoidCallback onPressed, //
      ) {
    return FilledButton.icon( //
      onPressed: onPressed, //
      icon: Icon(icon, size: 36), //
      label: Text( //
        text, //
        textAlign: TextAlign.center, //
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), //
      ),
      style: FilledButton.styleFrom( //
        padding: const EdgeInsets.symmetric(vertical: 20), //
        shape: RoundedRectangleBorder( //
          borderRadius: BorderRadius.circular(12), //
        ),
      ),
    );
  }

  Widget _buildRandomPickButton( //
      BuildContext context, //
      String text, //
      IconData icon, //
      VoidCallback onPressed, //
      Color backgroundColor, //
      ) {
    return SizedBox( //
      width: double.infinity, //
      child: ElevatedButton.icon( //
        icon: Icon(icon, size: 24), //
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), //
        onPressed: onPressed, //
        style: ElevatedButton.styleFrom( //
          padding: const EdgeInsets.symmetric(vertical: 15), //
          shape: RoundedRectangleBorder( //
            borderRadius: BorderRadius.circular(12), //
          ),
        ),
      ),
    );
  }

  Widget _buildMediaList(BuildContext context, List<MediaItem> items) { //
    return ListView.builder( //
      scrollDirection: Axis.horizontal, //
      itemCount: items.length, //
      itemBuilder: (context, index) { //
        final item = items[index]; //
        final heroTag = 'poster_${item.id}_${item.isMovie}_homelist'; //

        return GestureDetector( //
          onTap: () { //
            Navigator.push( //
              context, //
              MaterialPageRoute( //
                builder: (context) => DetailsScreen(item: item, heroTag: heroTag), //
              ),
            );
          },
          child: Card( //
            elevation: 1.0, //
            clipBehavior: Clip.antiAlias, //
            shape: RoundedRectangleBorder( //
              borderRadius: BorderRadius.circular(12.0), //
            ),
            margin: const EdgeInsets.only(right: 12), //
            child: SizedBox( //
              width: 120, //
              child: Column( //
                crossAxisAlignment: CrossAxisAlignment.start, //
                children: [ //
                  Expanded( //
                    child: Hero( //
                      tag: heroTag, //
                      child: CachedNetworkImage( //
                        imageUrl: item.posterUrl, //
                        fit: BoxFit.cover, //
                        width: 120, //
                        placeholder: (context, url) => Container( //
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), //
                          child: Center( //
                            child: CircularProgressIndicator( //
                              strokeWidth: 2, //
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container( //
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), //
                          child: Icon( //
                            Icons.movie_creation_outlined, //
                            color: Theme.of(context).colorScheme.onSurfaceVariant, //
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding( //
                    padding: const EdgeInsets.all(8.0), //
                    child: Text( //
                      item.title, //
                      maxLines: 2, //
                      overflow: TextOverflow.ellipsis, //
                      style: Theme.of(context).textTheme.bodySmall?.copyWith( //
                        color: Theme.of(context).colorScheme.onSurface, //
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        // Apply animations to the Card (or its child GestureDetector/SizedBox)
            .animate() // Extension method from flutter_animate
            .fadeIn(duration: 500.ms) // Fade in over 500 milliseconds
            .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutCubic); // Slide up
        // Optional: add a delay for a staggered effect if items are loaded sequentially
        // .then(delay: (index * 100).ms) // Stagger delay based on index - more useful for vertical lists
      },
    );
  }

  @override
  Widget build(BuildContext context) { //
    if (_isOffline) { //
      return OfflineScreen( //
        onRetry: () { //
          _checkConnectivity(); //
          setState(() {}); //
        },
      );
    }

    return Scaffold( //
      appBar: AppBar( //
        title: Text('Reel Deal', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          // Add Settings Icon Button
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ], //
      ),
      body: SingleChildScrollView( //
        physics: const AlwaysScrollableScrollPhysics(), //
        child: Padding( //
          padding: const EdgeInsets.all(16.0), //
          child: Column( //
            crossAxisAlignment: CrossAxisAlignment.start, //
            children: [ //
              Row( //
                children: [ //
                  Expanded( //
                    child: _buildDealButton( //
                      context, //
                      'Movie Deal', //
                      Icons.movie, //
                          () => Navigator.push( //
                        context, //
                        MaterialPageRoute( //
                          builder: (context) => //
                          const FilterScreen(isMovie: true), //
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), //
                  Expanded( //
                    child: _buildDealButton( //
                      context, //
                      'TV Deal', //
                      Icons.tv, //
                          () => Navigator.push( //
                        context, //
                        MaterialPageRoute( //
                          builder: (context) => //
                          const FilterScreen(isMovie: false), //
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24), //

              _buildRandomPickButton( //
                context, //
                'Random Movie Pick!', //
                Icons.shuffle_rounded, //
                    () => _getRandomMediaItem(context, isMovie: true), //
                Colors.blueAccent, //
              ),
              const SizedBox(height: 16), //
              _buildRandomPickButton( //
                context, //
                'Random TV Show Pick!', //
                Icons.casino_rounded, //
                    () => _getRandomMediaItem(context, isMovie: false), //
                Colors.greenAccent, //
              ),
              const SizedBox(height: 24), //


              Text( //
                'Popular Movies Today', //
                style: Theme.of(context).textTheme.titleLarge, //
              ),
              const SizedBox(height: 8), //
              RefreshIndicator( //
                onRefresh: () async { //
                  if (mounted) { //
                    setState(() {}); //
                  }
                  return Future.value(); //
                },
                child: SizedBox( //
                  height: 200, //
                  child: FutureBuilder<List<MediaItem>>( //
                    future: tmdbService.getPopularMovies(), //
                    builder: (context, snapshot) { //
                      if (snapshot.connectionState == //
                          ConnectionState.waiting) { //
                        return const Center( //
                            child: CircularProgressIndicator()); //
                      } else if (snapshot.hasError) { //
                        return Text('Error: ${snapshot.error}'); //
                      } else if (!snapshot.hasData || //
                          snapshot.data!.isEmpty) { //
                        return const Text('No movies found'); //
                      }
                      for (var i = 0; //
                      i < min(3, snapshot.data!.length); //
                      i++) {
                        precacheImage( //
                            NetworkImage(snapshot.data![i].posterUrl), //
                            context); //
                      }
                      return _buildMediaList(context, snapshot.data!); //
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24), //

              Text( //
                'Popular TV Shows Today', //
                style: Theme.of(context).textTheme.titleLarge, //
              ),
              const SizedBox(height: 8), //
              RefreshIndicator( //
                onRefresh: () async { //
                  if (mounted) { //
                    setState(() {}); //
                  }
                  return Future.value(); //
                },
                child: SizedBox( //
                  height: 200, //
                  child: FutureBuilder<List<MediaItem>>( //
                    future: tmdbService.getPopularTVShows(), //
                    builder: (context, snapshot) { //
                      if (snapshot.connectionState == //
                          ConnectionState.waiting) { //
                        return const Center( //
                            child: CircularProgressIndicator()); //
                      } else if (snapshot.hasError) { //
                        return Text('Error: ${snapshot.error}'); //
                      } else if (!snapshot.hasData || //
                          snapshot.data!.isEmpty) { //
                        return const Text('No TV shows found'); //
                      }
                      for (var i = 0; //
                      i < min(3, snapshot.data!.length); //
                      i++) {
                        precacheImage( //
                            NetworkImage(snapshot.data![i].posterUrl), //
                            context); //
                      }
                      return _buildMediaList(context, snapshot.data!); //
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24), //
              Text( //
                'Popular Movies of All Time', //
                style: Theme.of(context).textTheme.titleLarge, //
              ),
              const SizedBox(height: 8), //
              RefreshIndicator( //
                onRefresh: () async { //
                  if (mounted) { //
                    setState(() {}); //
                  }
                  return Future.value(); //
                },
                child: SizedBox( //
                  height: 200, //
                  child: FutureBuilder<List<MediaItem>>( //
                    future: tmdbService.getTopRatedMovies(), //
                    builder: (context, snapshot) { //
                      if (snapshot.connectionState == ConnectionState.waiting) { //
                        return const Center(child: CircularProgressIndicator()); //
                      } else if (snapshot.hasError) { //
                        return Text('Error: ${snapshot.error}'); //
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) { //
                        return const Text('No all-time popular movies found'); //
                      }
                      for (var i = 0; i < min(3, snapshot.data!.length); i++) { //
                        precacheImage(NetworkImage(snapshot.data![i].posterUrl), context); //
                      }
                      return _buildMediaList(context, snapshot.data!); //
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24), //
              Text( //
                'Popular TV Shows of All Time', //
                style: Theme.of(context).textTheme.titleLarge, //
              ),
              const SizedBox(height: 8), //
              RefreshIndicator( //
                onRefresh: () async { //
                  if (mounted) { //
                    setState(() {}); //
                  }
                  return Future.value(); //
                },
                child: SizedBox( //
                  height: 200, //
                  child: FutureBuilder<List<MediaItem>>( //
                    future: tmdbService.getTopRatedTVShows(), //
                    builder: (context, snapshot) { //
                      if (snapshot.connectionState == ConnectionState.waiting) { //
                        return const Center(child: CircularProgressIndicator()); //
                      } else if (snapshot.hasError) { //
                        return Text('Error: ${snapshot.error}'); //
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) { //
                        return const Text('No all-time popular TV shows found'); //
                      }
                      for (var i = 0; i < min(3, snapshot.data!.length); i++) { //
                        precacheImage(NetworkImage(snapshot.data![i].posterUrl), context); //
                      }
                      return _buildMediaList(context, snapshot.data!); //
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
}
