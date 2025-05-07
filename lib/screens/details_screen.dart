import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTrailer();
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
          // App Bar with backdrop image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.item.backdropUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[900]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),

          // Content
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
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              Text(' ${widget.item.rating}/10'),
                              const SizedBox(width: 16),
                              Text('(${widget.item.year})'),
                            ],
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
                                    width: 80,
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
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
