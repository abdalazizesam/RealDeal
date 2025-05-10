import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../providers/watchlist_provider.dart';
import 'details_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sortByRating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MediaItem> _getSortedItems(List<MediaItem> items) {
    if (_sortByRating) {
      // Create a copy of the list so we don't modify the original
      final sortedItems = List<MediaItem>.from(items);
      // Sort by rating in descending order (highest first)
      sortedItems.sort((a, b) => b.rating.compareTo(a.rating));
      return sortedItems;
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          // Sort button
          IconButton(
            icon: Icon(
              _sortByRating ? Icons.sort : Icons.sort_outlined,
              color: _sortByRating ? Colors.amber : Colors.white,
            ),
            tooltip: 'Sort by rating',
            onPressed: () {
              setState(() {
                _sortByRating = !_sortByRating;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, watchlistProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              // Movies tab
              _buildWatchlistTab(_getSortedItems(watchlistProvider.getMoviesWatchlist())),

              // TV Shows tab
              _buildWatchlistTab(_getSortedItems(watchlistProvider.getTVShowsWatchlist())),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWatchlistTab(List<MediaItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/empty.json', width: 200, height: 200),
            const SizedBox(height: 16),
            const Text('Your watchlist is empty'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: Key(item.id.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            Provider.of<WatchlistProvider>(context, listen: false)
                .removeFromWatchlist(item.id);
          },
          child: Card(
            color: Colors.grey[850],
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.posterUrl,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 75,
                    color: Colors.grey[800],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                  // Rating indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRatingColor(item.rating),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 16),
                        SizedBox(width: 2),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '${item.year} • ${item.genres.take(2).join(', ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  Provider.of<WatchlistProvider>(context, listen: false)
                      .removeFromWatchlist(item.id);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsScreen(item: item),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Helper method to get color based on rating
  Color _getRatingColor(double rating) {
    if (rating >= 8.0) {
      return Colors.green;
    } else if (rating >= 6.0) {
      return Colors.amber.shade800;
    } else if (rating >= 4.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}