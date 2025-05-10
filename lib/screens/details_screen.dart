import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/media_item.dart';
import '../providers/watchlist_provider.dart';
import '../services/tmdb_service.dart';
import '../widgets/youtube_player_widget.dart'; // Make sure this exists

class DetailsScreen extends StatefulWidget {
  final MediaItem item;

  const DetailsScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final tmdbService = TmdbService();
  String? trailerUrl;
  bool isLoadingTrailer = true;
  String? duration;
  bool isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadTrailer();
    _loadDurationDetails();
  }

  Widget _buildShimmerPlaceholder() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      color: Colors.grey[800],
                      width: 120,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Shimmer.fromColors(
                baseColor: Colors.grey[800]!,
                highlightColor: Colors.grey[700]!,
                child: Container(
                  height: 12,
                  width: 100,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadDurationDetails() async {
    try {
      if (widget.item.isMovie) {
        final details = await tmdbService.getMovieDetails(widget.item.id);
        if (mounted) {
          setState(() {
            duration = details['duration'];
            isLoadingDetails = false;
          });
        }
      } else {
        final details = await tmdbService.getTVShowDetails(widget.item.id);
        if (mounted) {
          setState(() {
            duration = details['duration'];
            isLoadingDetails = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _loadTrailer() async {
    try {
      final url = await tmdbService.getTrailerUrl(widget.item.id, widget.item.isMovie);
      if (mounted) {
        setState(() {
          trailerUrl = url;
          isLoadingTrailer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingTrailer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlistProvider = Provider.of<WatchlistProvider>(context);
    final isInWatchlist = watchlistProvider.isInWatchlist(widget.item.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Blurred App Bar with backdrop image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop image
                  CachedNetworkImage(
                    imageUrl: widget.item.backdropUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[900]),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Custom leading button with stylized back arrow
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ),
                ),
              ),
            ),
            // Add blurred background to app bar when scrolled
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content - Keep the rest of your code as is
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Poster, title and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.item.posterUrl,
                        height: 180,
                        width: 120,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          height: 180,
                          width: 120,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          height: 180,
                          width: 120,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Title and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // FIXED LAYOUT FOR RATING AND YEAR - MOVED TO SEPARATE ROWS
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              Text(' ${widget.item.rating}/10'),
                              const SizedBox(width: 12),
                              Text('(${widget.item.year})'),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // SEPARATE ROW FOR DURATION - FIXES OVERFLOW
                          if (duration != null)
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.grey, size: 18),
                                Flexible(
                                  child: Text(
                                    ' $duration',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else if (isLoadingDetails)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),

                          const SizedBox(height: 12),
                          // Genre tags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.item.genres.map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  genre,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),
                          // Watchlist Button
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isInWatchlist) {
                                watchlistProvider.removeFromWatchlist(widget.item.id);
                              } else {
                                watchlistProvider.addToWatchlist(widget.item);
                              }
                            },
                            icon: Icon(isInWatchlist ? Icons.check : Icons.add),
                            label: Text(
                              isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                              style: TextStyle(color: Colors.blue.shade100),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInWatchlist ? Colors.green : Colors.red,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Trailer Button
                          if (isLoadingTrailer)
                            const SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (trailerUrl != null)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => YoutubePlayerWidget(url: trailerUrl!),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Watch Trailer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Overview
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.item.overview),

                const SizedBox(height: 24),

                // Cast section
                const Text(
                  'Cast',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: tmdbService.getCast(widget.item.id, widget.item.isMovie),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error loading cast: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No cast information available');
                    }

                    return SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final castMember = snapshot.data![index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: CachedNetworkImage(
                                    imageUrl: castMember['profileUrl'] ?? '',
                                    height: 80,
                                    width: 90,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      height: 80,
                                      width: 80,
                                      color: Colors.grey[800],
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      height: 80,
                                      width: 80,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  castMember['name'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  castMember['character'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Similar Content section
                const Text(
                  'Similar Content',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: FutureBuilder<List<MediaItem>>(
                    future: widget.item.isMovie
                        ? tmdbService.getSimilarMovies(widget.item.id)
                        : tmdbService.getSimilarTVShows(widget.item.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerPlaceholder();
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 40),
                              const SizedBox(height: 8),
                              Text('Error: ${snapshot.error}'),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No similar content available'),
                        );
                      }

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final item = snapshot.data![index];
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
                    },
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}