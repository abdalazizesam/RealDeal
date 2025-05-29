import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import 'details_screen.dart';
import 'actor_details_screen.dart';

const String _recentSearchesKey = 'recent_searches';
const int _maxRecentSearches = 7;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  // _currentDisplayQuery is used to hold the query for which results are currently shown
  String _currentDisplayQuery = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchTextChanged);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
    });
  }

  Future<void> _saveQueryToRecentSearches(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    // Create a new list from _recentSearches to avoid modifying the state variable directly before setState
    List<String> currentSearches = List<String>.from(_recentSearches);

    currentSearches.removeWhere((s) => s.toLowerCase() == trimmedQuery.toLowerCase());
    currentSearches.insert(0, trimmedQuery);

    if (currentSearches.length > _maxRecentSearches) {
      currentSearches = currentSearches.sublist(0, _maxRecentSearches);
    }

    if (!mounted) return;
    setState(() {
      _recentSearches = currentSearches;
    });
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentSearches = List<String>.from(_recentSearches);
    currentSearches.removeWhere((s) => s.toLowerCase() == query.toLowerCase());
    if (!mounted) return;
    setState(() {
      _recentSearches = currentSearches;
    });
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  Future<void> _clearAllRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentSearches = [];
    });
    await prefs.remove(_recentSearchesKey);
  }

  void _onSearchTextChanged() {
    // This triggers fetching live results via debouncing
    // but does not yet save the search or dismiss keyboard
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _fetchLiveResults(query);
      } else {
        // If text is cleared, clear results and show recents/empty prompt
        if (!mounted) return;
        setState(() {
          _searchResults = [];
          _currentDisplayQuery = '';
          _isLoading = false;
        });
      }
    });
    // Update UI for clear button visibility
    if (mounted) setState(() {});
  }

  // Fetches results for display as user types (suggestions)
  Future<void> _fetchLiveResults(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _currentDisplayQuery = '';
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentDisplayQuery = query;
    });

    try {
      final movies = await _tmdbService.searchMovies(query);
      final tvShows = await _tmdbService.searchTVShows(query);
      final actors = await _tmdbService.searchActors(query);

      if (!mounted) return;
      setState(() {
        _searchResults = [...movies, ...tvShows, ...actors];
        _searchResults.sort((a, b) {
          final double popularityA = a is MediaItem ? a.rating : (a['popularity'] ?? 0.0).toDouble();
          final double popularityB = b is MediaItem ? b.rating : (b['popularity'] ?? 0.0).toDouble();
          return popularityB.compareTo(popularityA);
        });
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // Optionally show a less intrusive error for live results, or just empty
      });
    }
  }

  // Called when a search is explicitly submitted (keyboard, recent tap)
  Future<void> _submitSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    _searchController.text = trimmedQuery; // Ensure controller has the text
    _searchController.selection = TextSelection.fromPosition(TextPosition(offset: trimmedQuery.length));
    _searchFocusNode.unfocus(); // Dismiss keyboard

    // Fetch results if not already fetched for this exact query or if current display query is different
    if (_currentDisplayQuery.toLowerCase() != trimmedQuery.toLowerCase() || _searchResults.isEmpty) {
      await _fetchLiveResults(trimmedQuery); // This will set _isLoading and _currentDisplayQuery
    }
    // Save to recent searches only after explicit submission
    // And only if the search isn't an empty result for that query
    if (_searchResults.isNotEmpty || (_currentDisplayQuery == trimmedQuery && _searchResults.isEmpty)) {
      // Save even if results are empty for that specific query, to indicate user searched for it.
      // Or, you could add a check: if (_searchResults.isNotEmpty) before saving.
      await _saveQueryToRecentSearches(trimmedQuery);
    }
  }


  void _showClearAllConfirmationDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: Text('Clear all recent searches?', style: TextStyle(color: colorScheme.onSurface)),
          content: Text('This action cannot be undone.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Clear All', style: TextStyle(color: colorScheme.error)),
              onPressed: () {
                _clearAllRecentSearches();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSearchesWidgets() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // This method assumes _recentSearches is NOT empty.
    // The check for emptiness should be done before calling this.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              TextButton(
                onPressed: _showClearAllConfirmationDialog,
                child: Text('Clear All', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSearches.length,
          itemBuilder: (context, index) {
            final recentQuery = _recentSearches[index];
            return ListTile(
              leading: Icon(Icons.history_rounded, color: colorScheme.onSurfaceVariant),
              title: Text(recentQuery, style: textTheme.bodyMedium),
              trailing: IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                tooltip: 'Remove from recent',
                onPressed: () => _removeRecentSearch(recentQuery),
              ),
              onTap: () => _submitSearch(recentQuery),
            ).animate().fadeIn(delay: (50 * index).ms);
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = Center(child: CircularProgressIndicator(color: colorScheme.primary));
    } else if (_searchController.text.isEmpty) { // When search bar is empty
      if (_recentSearches.isNotEmpty) {
        bodyContent = SingleChildScrollView(child: _buildRecentSearchesWidgets());
      } else {
        bodyContent = Center(
          child: Text(
            "No recent searches.", // User requested simple message
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        );
      }
    } else if (_searchResults.isEmpty && _currentDisplayQuery.isNotEmpty) { // Searched, but no results
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'No results found for "$_currentDisplayQuery"',
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_searchResults.isNotEmpty) { // Have results to show
      bodyContent = ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          Widget tile;
          if (result is MediaItem) {
            tile = _buildMediaItemTile(result, index);
          } else { // Actor
            tile = _buildActorTile(result, index);
          }
          return tile.animate()
              .fadeIn(duration: 300.ms, delay: (50 * index).ms)
              .slideY(begin: 0.1, end: 0, duration: 250.ms, delay: (50 * index).ms, curve: Curves.easeOutCubic);
        },
      );
    } else { // Fallback (e.g. text in bar, but debounce hasn't fired, or initial state before any interaction)
      if (_recentSearches.isNotEmpty) {
        bodyContent = SingleChildScrollView(child: _buildRecentSearchesWidgets());
      } else {
        bodyContent = Center(
          child: Text(
            "No recent searches.",
            style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Card(
            elevation: 1.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
            color: colorScheme.surfaceContainerHighest,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: false,
              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
                hintText: 'Search movies, TV, actors...',
                hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 10.0),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear(); // This will trigger _onSearchTextChanged
                    // If keyboard is open, it will remain open for new input
                    // if not open, it won't open.
                  },
                )
                    : null,
              ),
              cursorColor: colorScheme.primary,
              onSubmitted: (value) => _submitSearch(value),
            ),
          ),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _buildMediaItemTile(MediaItem item, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final heroTag = 'search_poster_${item.id}_${item.isMovie}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Hero(
        tag: heroTag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: item.posterUrl,
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: colorScheme.surfaceVariant.withOpacity(0.3), width: 50, height: 75,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
            ),
            errorWidget: (context, url, error) => Container(
              color: colorScheme.surfaceVariant.withOpacity(0.3), width: 50, height: 75,
              child: Icon(Icons.movie_creation_outlined, color: colorScheme.onSurfaceVariant, size: 24),
            ),
          ),
        ),
      ),
      title: Text(item.title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(
        '${item.isMovie ? 'Movie' : 'TV Show'} • ${item.year}${item.genres.isNotEmpty ? ' • ${item.genres.take(2).join(', ')}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: item.rating > 0 ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            item.rating.toStringAsFixed(1),
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ) : null,
      onTap: () {
        if(item.title.isNotEmpty && item.id != 0) {
          _submitSearch(item.title); // Submit and save the item's title as a search
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(item: item, heroTag: heroTag),
            ),
          );
        }
      },
    );
  }

  Widget _buildActorTile(Map<String, dynamic> actor, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final heroTag = 'search_actor_${actor['id']}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Hero(
        tag: heroTag,
        child: CircleAvatar(
          radius: 28,
          backgroundImage: CachedNetworkImageProvider(actor['profileUrl']),
          backgroundColor: colorScheme.surfaceVariant,
          child: (actor['profileUrl'] == null || (actor['profileUrl'] as String).contains('placeholder'))
              ? Icon(Icons.person_outline_rounded, size: 28, color: colorScheme.onSurfaceVariant)
              : null,
        ),
      ),
      title: Text(actor['name'], style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      subtitle: Text(
        'Actor - Pop: ${(actor['popularity'] ?? 0.0).toStringAsFixed(1)}',
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
      onTap: () {
        _submitSearch(actor['name']); // Submit and save the actor's name as a search
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