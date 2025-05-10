import 'dart:async'; // Added for StreamSubscription
import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../screens/filter_screen.dart';
import '../screens/details_screen.dart';
import '../screens/offline_screen.dart'; // Added
import 'package:connectivity_plus/connectivity_plus.dart'; // Added

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService tmdbService = TmdbService();

  bool _isOffline = false;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await ConnectivityHelper.isConnected();
    setState(() {
      _isOffline = !isConnected;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        ConnectivityHelper.connectivityStream.listen((result) {
          setState(() {
            _isOffline = result == ConnectivityResult.none;
          });
        });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineScreen(
        onRetry: () {
          _checkConnectivity();
          setState(() {});
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reel Deal', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Deal Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildDealButton(
                      context,
                      'Movie Deal',
                      Icons.movie,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const FilterScreen(isMovie: true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDealButton(
                      context,
                      'TV Deal',
                      Icons.tv,
                          () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const FilterScreen(isMovie: false),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Popular Movies
              const Text(
                'Popular Movies Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  return Future.value();
                },
                child: SizedBox(
                  height: 200,
                  child: FutureBuilder<List<MediaItem>>(
                    future: tmdbService.getPopularMovies(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Text('No movies found');
                      }

                      for (var i = 0;
                      i < min(3, snapshot.data!.length);
                      i++) {
                        precacheImage(
                            NetworkImage(snapshot.data![i].posterUrl),
                            context);
                      }

                      return _buildMediaList(context, snapshot.data!);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Popular TV Shows
              const Text(
                'Popular TV Shows Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  return Future.value();
                },
                child: SizedBox(
                  height: 200,
                  child: FutureBuilder<List<MediaItem>>(
                    future: tmdbService.getPopularTVShows(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Text('No TV shows found');
                      }

                      for (var i = 0;
                      i < min(3, snapshot.data!.length);
                      i++) {
                        precacheImage(
                            NetworkImage(snapshot.data![i].posterUrl),
                            context);
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
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList(BuildContext context, List<MediaItem> items) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(item: item),
              ),
            );
          },
          child: Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.posterUrl,
                      fit: BoxFit.cover,
                      width: 120,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
