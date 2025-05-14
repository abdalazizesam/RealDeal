import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
  String sortBy = 'date_added'; // Default sorting option (date_added or rating)

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
    // Create a copy of the list so we don't modify the original
    final sortedItems = List<MediaItem>.from(items);

    if (sortBy == 'rating') {
      // Sort by rating in descending order (highest first)
      sortedItems.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      // Default: sort by date added (newest first)
      // This assumes MediaItem has a dateAdded property or we're using the original order
      // If your WatchlistProvider already maintains this order, you can leave this as-is
    }

    return sortedItems;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              // Sort title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: const [
                    Icon(Icons.sort_rounded, color: Colors.red, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Sort Watchlist',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Colors.grey,
                thickness: 0.5,
                indent: 20,
                endIndent: 20,
              ),
              // Sort options
              _buildSortOption(
                title: 'Date Added',
                icon: Icons.calendar_today_rounded,
                value: 'date_added',
              ),
              _buildSortOption(
                title: 'Rating',
                icon: Icons.star_rounded,
                value: 'rating',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final bool isSelected = sortBy == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() {
            sortBy = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.red : Colors.grey[400],
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Watchlist', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        actions: [
          // Sort button with blurred background
          Padding(
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
                    icon: const Icon(
                      Icons.sort_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Sort by',
                    onPressed: _showSortOptions,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ),
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