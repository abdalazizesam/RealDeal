import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import 'details_screen.dart';
import 'package:shimmer/shimmer.dart';

class ActorDetailsScreen extends StatefulWidget {
  final String actorName;
  final String profileUrl;
  final int actorId;

  const ActorDetailsScreen({
    Key? key,
    required this.actorName,
    required this.profileUrl,
    required this.actorId,
  }) : super(key: key);

  @override
  State<ActorDetailsScreen> createState() => _ActorDetailsScreenState();
}

class _ActorDetailsScreenState extends State<ActorDetailsScreen> {
  final TmdbService tmdbService = TmdbService();
  List<MediaItem> actorFilmography = [];
  bool isLoading = true;
  String sortBy = 'popularity'; // Default sorting option
  String? errorMessage;
  String? biography;
  String? birthday;
  String? placeOfBirth;

  @override
  void initState() {
    super.initState();
    _loadActorDetails();
    _loadFilmography();
  }

  Future<void> _loadActorDetails() async {
    try {
      final details = await tmdbService.getActorDetails(widget.actorId);
      if (mounted) {
        setState(() {
          biography = details['biography'];
          birthday = details['birthday'];
          placeOfBirth = details['placeOfBirth'];
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadFilmography() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final filmography = await tmdbService.getActorFilmography(widget.actorId, sortBy);
      if (mounted) {
        setState(() {
          actorFilmography = filmography;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load filmography: ${e.toString()}';
          isLoading = false;
        });
      }
    }
  }

  void _sortFilmography(String sortOption) {
    setState(() {
      sortBy = sortOption;
    });
    _loadFilmography();
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
                      'Sort Filmography',
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
                title: 'Popularity',
                icon: Icons.trending_up_rounded,
                value: 'popularity',
              ),
              _buildSortOption(
                title: 'Rating',
                icon: Icons.star_rounded,
                value: 'vote_average',
              ),
              _buildSortOption(
                title: 'Release Date',
                icon: Icons.calendar_today_rounded,
                value: 'release_date',
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
          _sortFilmography(value);
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

  Widget _buildShimmerPlaceholder() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Poster placeholder
                Shimmer.fromColors(
                  baseColor: Colors.grey[800]!,
                  highlightColor: Colors.grey[700]!,
                  child: Container(
                    height: 90,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(
                          height: 14,
                          width: 120,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[700]!,
                        child: Container(
                          height: 10,
                          width: 80,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullBiography() {
    if (biography == null || biography!.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            '${widget.actorName}\'s Biography',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Text(
              biography!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // This allows content to go behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.actorName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
        actions: [
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
        // Add blurred gradient line at the bottom of app bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFilmography,
        child: CustomScrollView(
          slivers: [
            // Adding a top space to account for the transparent app bar
            const SliverToBoxAdapter(
              child: SizedBox(height: kToolbarHeight + 8),
            ),

            // Actor profile header
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(12),
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Actor image and basic info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Actor image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: widget.profileUrl,
                              height: 120,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[800],
                                height: 120,
                                width: 80,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                height: 120,
                                width: 80,
                                child: const Icon(Icons.person),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.actorName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                if (birthday != null && birthday!.isNotEmpty)
                                  Text(
                                    'Born: $birthday',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[300],
                                    ),
                                  ),

                                if (placeOfBirth != null && placeOfBirth!.isNotEmpty)
                                  Text(
                                    'Place of Birth: $placeOfBirth',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Biography section
                      if (biography != null && biography!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text(
                          'Biography',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          biography!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[300],
                          ),
                        ),
                        TextButton(
                          onPressed: _showFullBiography,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text(
                            'Read More',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Filmography header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filmography',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isLoading)
                      Text(
                        'Sorted by: ${_getSortLabel(sortBy)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Filmography content
            isLoading
                ? SliverFillRemaining(child: _buildShimmerPlaceholder())
                : errorMessage != null
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFilmography,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
                : actorFilmography.isEmpty
                ? const SliverFillRemaining(
              child: Center(child: Text('No filmography available')),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final mediaItem = actorFilmography[index];
                  return Card(
                    margin: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      top: index == 0 ? 4 : 0,
                    ),
                    color: Colors.grey[900],
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(item: mediaItem),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Poster
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: mediaItem.posterUrl,
                                height: 90,
                                width: 60,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  height: 90,
                                  width: 60,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  height: 90,
                                  width: 60,
                                  child: const Icon(Icons.image_not_supported, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title and info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mediaItem.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        mediaItem.year,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      Text(
                                        ' ${mediaItem.rating}',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Character name if available
                                  if (mediaItem.character != null && mediaItem.character!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'as ${mediaItem.character}',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],

                                  // Genre tags
                                  if (mediaItem.genres.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: mediaItem.genres.take(3).map((genre) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            genre,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: actorFilmography.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortOption) {
    switch (sortOption) {
      case 'popularity':
        return 'Popularity';
      case 'vote_average':
        return 'Rating';
      case 'release_date':
        return 'Release Date';
      default:
        return 'Popularity';
    }
  }
}