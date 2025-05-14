import 'dart:async';
import 'dart:ui'; // Import for BackdropFilter

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import 'details_screen.dart';
import 'actor_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty && _searchController.text != _searchQuery) {
        setState(() {
          _searchQuery = _searchController.text;
          _performSearch(_searchQuery);
        });
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
          _searchQuery = '';
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Search for movies, TV shows, and actors
      final movies = await _tmdbService.searchMovies(query);
      final tvShows = await _tmdbService.searchTVShows(query);
      final actors = await _tmdbService.searchActors(query);

      setState(() {
        // Combine and sort results by popularity
        _searchResults = [...movies, ...tvShows, ...actors];
        _searchResults.sort((a, b) {
          final double popularityA = a is MediaItem ? a.rating : (a['popularity'] ?? 0).toDouble();
          final double popularityB = b is MediaItem ? b.rating : (b['popularity'] ?? 0).toDouble();
          return popularityB.compareTo(popularityA);
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search movies, TV shows, actors...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
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
                        Icons.clear,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty && _searchQuery.isNotEmpty
          ? const Center(child: Text('No results found'))
          : _searchResults.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for movies, TV shows, or actors',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          if (result is MediaItem) {
            return _buildMediaItemTile(result);
          } else {
            return _buildActorTile(result);
          }
        },
      ),
    );
  }

  Widget _buildMediaItemTile(MediaItem item) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: item.posterUrl,
          width: 50,
          height: 75,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            width: 50,
            height: 75,
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            width: 50,
            height: 75,
            child: const Icon(Icons.error),
          ),
        ),
      ),
      title: Text(item.title, style: TextStyle(color: Colors.white)),
      subtitle: Text(
        '${item.isMovie ? 'Movie' : 'TV Show'} · ${item.year} · ${item.genres.join(', ')}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(item.rating.toStringAsFixed(1)),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(item: item),
          ),
        );
      },
    );
  }

  Widget _buildActorTile(Map<String, dynamic> actor) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: CachedNetworkImage(
          imageUrl: actor['profileUrl'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            width: 50,
            height: 50,
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            width: 50,
            height: 50,
            child: const Icon(Icons.person),
          ),
        ),
      ),
      title: Text(actor['name']),
      subtitle: const Text('Actor'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActorDetailsScreen(
              actorId: actor['id'],
              actorName: actor['name'],
              profileUrl: actor['profileUrl'],
            ),
          ),
        );
      },
    );
  }
}