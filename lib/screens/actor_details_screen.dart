import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../services/tmdb_service.dart';
import '../widgets/error_display_widget.dart';
import 'details_screen.dart';
import 'dart:ui' as ui;

class ActorDetailsScreen extends StatefulWidget {
  final String actorName;
  final String profileUrl;
  final int actorId;
  final String? heroTag;

  const ActorDetailsScreen({
    Key? key,
    required this.actorName,
    required this.profileUrl,
    required this.actorId,
    this.heroTag,
  }) : super(key: key);

  @override
  State<ActorDetailsScreen> createState() => _ActorDetailsScreenState();
}

class _ActorDetailsScreenState extends State<ActorDetailsScreen> {
  final TmdbService _tmdbService = TmdbService();

  String? _biography;
  DateTime? _birthday; // Changed to DateTime for easier formatting
  String? _placeOfBirth;
  bool _isLoadingDetails = true;
  bool _hasDetailsError = false; // Error flag for actor details

  List<MediaItem> _knownForItems = [];
  bool _isLoadingKnownFor = true;
  bool _hasKnownForError = false; // Error flag for known for section
  final int _knownForLimit = 8;

  List<MediaItem> _completeFilmographyList = [];
  List<MediaItem> _displayedFilmographyItems = [];
  bool _isLoadingFullFilmography = true;
  bool _hasFilmographyError = false; // Error flag for filmography section
  String _sortBy = 'popularity';

  final int _filmographyBatchSize = 10;
  bool _canLoadMoreFilmography = false;
  bool _isLoadingMoreFilmography = false;

  final GlobalKey _biographyTextKey = GlobalKey(); // Key to measure biography text
  bool _isBiographyExpanded = false;
  bool _isBiographyOverflowing = false;

  @override
  void initState() {
    super.initState();
    _loadAllActorData();
  }

  // No dispose for now as no specific controllers/streams added

  Future<void> _loadAllActorData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingDetails = true;
      _isLoadingKnownFor = true;
      _isLoadingFullFilmography = true;
      _hasDetailsError = false;
      _hasKnownForError = false;
      _hasFilmographyError = false;
      _biography = null;
      _birthday = null;
      _placeOfBirth = null;
      _knownForItems = [];
      _completeFilmographyList = [];
      _displayedFilmographyItems = [];
      _canLoadMoreFilmography = false;
      _isBiographyExpanded = false; // Reset biography state
      _isBiographyOverflowing = false;
    });

    await Future.wait([
      _loadActorDetails(),
      _loadKnownFor(),
      _fetchAndDisplayFullFilmography(), // This handles its own loading state
    ]).then((_) {
      // All futures completed, now check for overflow for biography
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkBiographyOverflow();
      });
    }).catchError((e) {
      // Catch any unhandled errors from Future.wait
      print('Unexpected error in Future.wait for ActorDetails: $e');
      if (mounted) setState(() => _hasDetailsError = true); // General error
    });
  }

  Future<void> _loadActorDetails() async {
    try {
      final actorDetails = await _tmdbService.getActorDetails(widget.actorId);
      if (mounted) {
        setState(() {
          _biography = actorDetails['biography'];
          if (actorDetails['birthday'] != null && actorDetails['birthday'].isNotEmpty) {
            try {
              _birthday = DateTime.parse(actorDetails['birthday']);
            } catch (e) {
              print('Error parsing birthday: $e');
              _birthday = null;
            }
          }
          _placeOfBirth = actorDetails['placeOfBirth'];
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      print('Error loading actor details: $e');
      if (mounted) setState(() => _hasDetailsError = true);
    }
  }

  Future<void> _loadKnownFor() async {
    try {
      final knownForList = await _tmdbService.getActorKnownFor(widget.actorId, limit: _knownForLimit);
      if (mounted) {
        setState(() {
          _knownForItems = knownForList;
          _isLoadingKnownFor = false;
        });
      }
    } catch (e) {
      print('Error loading known for items: $e');
      if (mounted) setState(() => _hasKnownForError = true);
    }
  }

  Future<void> _fetchAndDisplayFullFilmography() async {
    if (!mounted) return;
    setState(() {
      _isLoadingFullFilmography = true;
      _hasFilmographyError = false; // Reset error flag
      _displayedFilmographyItems = [];
      _canLoadMoreFilmography = false;
    });

    try {
      _completeFilmographyList = await _tmdbService.getActorFilmography(widget.actorId, _sortBy);
      if (!mounted) return;
      _updateDisplayedFilmography();
      setState(() {
        _isLoadingFullFilmography = false;
      });
    } catch (e) {
      print('Failed to load filmography: $e');
      if (mounted) {
        setState(() {
          _hasFilmographyError = true;
          _completeFilmographyList = [];
          _updateDisplayedFilmography();
          _isLoadingFullFilmography = false;
        });
      }
    }
  }

  void _updateDisplayedFilmography() {
    final currentLength = _displayedFilmographyItems.length;
    int itemsToTake = _filmographyBatchSize;

    if (currentLength == 0) {
      itemsToTake = _filmographyBatchSize;
      _displayedFilmographyItems = _completeFilmographyList.take(itemsToTake).toList();
    } else {
      if (currentLength + _filmographyBatchSize > _completeFilmographyList.length) {
        itemsToTake = _completeFilmographyList.length - currentLength;
      }
      if (itemsToTake > 0) {
        _displayedFilmographyItems.addAll(
            _completeFilmographyList.skip(currentLength).take(itemsToTake)
        );
      }
    }

    setState(() {
      _canLoadMoreFilmography = _displayedFilmographyItems.length < _completeFilmographyList.length;
      _isLoadingMoreFilmography = false;
    });
  }

  void _loadMoreFilmographyItems() {
    if (_isLoadingMoreFilmography || !_canLoadMoreFilmography) return;
    if (!mounted) return;
    setState(() {
      _isLoadingMoreFilmography = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _updateDisplayedFilmography();
    });
  }

  void _applySortAndReloadFilmography(String sortOption) {
    if (_sortBy == sortOption && !_isLoadingFullFilmography) return;
    setState(() {
      _sortBy = sortOption;
    });
    HapticFeedback.lightImpact();
    _fetchAndDisplayFullFilmography();
  }

  void _showSortOptions() {
    HapticFeedback.lightImpact();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28.0),
              topRight: Radius.circular(28.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 4, decoration: BoxDecoration(color: colorScheme.onSurfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Text('Sort Filmography By', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface))),
              const SizedBox(height: 8),
              _buildSortOption(title: 'Popularity', icon: Icons.trending_up_rounded, value: 'popularity'),
              _buildSortOption(title: 'Rating', icon: Icons.star_border_rounded, value: 'vote_average'),
              _buildSortOption(title: 'Release Date', icon: Icons.calendar_today_rounded, value: 'release_date'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption({required String title, required IconData icon, required String value}) {
    final bool isSelected = _sortBy == value;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
          _applySortAndReloadFilmography(value);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(isSelected ? ((value == 'popularity') ? Icons.trending_up_rounded : (value == 'vote_average' ? Icons.star_rounded : Icons.event_available_rounded)) : icon, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant, size: 22),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: textTheme.bodyLarge?.copyWith(color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
              if (isSelected) Icon(Icons.check_circle_rounded, color: colorScheme.onPrimaryContainer, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerActorDetails() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: colorScheme.surfaceContainerHighest,
        highlightColor: colorScheme.surfaceContainerHigh,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 24, width: 200, color: Colors.white, margin: const EdgeInsets.only(top: 4, bottom: 8)),
                      Container(height: 16, width: 150, color: Colors.white, margin: const EdgeInsets.only(bottom: 4)),
                      Container(height: 16, width: 180, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 20, width: 120, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 14, width: double.infinity, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 14, width: double.infinity, color: Colors.white),
            const SizedBox(height: 6),
            Container(height: 14, width: 250, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerHorizontalList() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemBuilder: (context, index) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: colorScheme.surfaceContainer,
            margin: const EdgeInsets.only(right: 12),
            clipBehavior: Clip.antiAlias,
            child: Shimmer.fromColors(
              baseColor: colorScheme.surfaceContainerHighest,
              highlightColor: colorScheme.surfaceContainerHigh,
              child: SizedBox(
                width: 120,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 12, width: 100, color: Colors.white),
                          const SizedBox(height: 4),
                          Container(height: 10, width: 80, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerFilmographyList() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) {
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: colorScheme.surfaceContainer,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Shimmer.fromColors(
              baseColor: colorScheme.surfaceContainerHighest,
              highlightColor: colorScheme.surfaceContainerHigh,
              child: Row(
                children: [
                  Container(
                    height: 100,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 18, width: 180, color: Colors.white, margin: const EdgeInsets.only(bottom: 6)),
                        Container(height: 14, width: 120, color: Colors.white, margin: const EdgeInsets.only(bottom: 4)),
                        Container(height: 14, width: 150, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Method to check if biography text overflows
  void _checkBiographyOverflow() {
    if (_biographyTextKey.currentContext == null) return;

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: _biography,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      maxLines: 4,
      textDirection: ui.TextDirection.ltr, // Use ui.TextDirection.ltr
    )..layout(maxWidth: _biographyTextKey.currentContext!.size!.width);

    if (mounted) {
      setState(() {
        _isBiographyOverflowing = textPainter.didExceedMaxLines;
      });
    }
  }
  void _showFullBiography() {
    if (_biography == null || _biography!.isEmpty) return;
    HapticFeedback.lightImpact(); // Haptic Feedback
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: Text('${widget.actorName}\'s Biography', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
          content: SingleChildScrollView(child: Text(_biography!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5))),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Text('Close', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKnownForItemCard(MediaItem item, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final knownForHeroTag = 'known_for_poster_${item.id}_${widget.actorId}';
    return SizedBox(
      width: 120,
      child: Card(
        elevation: 1.5,
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(item: item, heroTag: knownForHeroTag)));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Hero(
                  tag: knownForHeroTag,
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: colorScheme.surfaceVariant.withOpacity(0.5)),
                    errorWidget: (context, url, error) => Container(color: colorScheme.surfaceVariant.withOpacity(0.5), child: Icon(Icons.movie_creation_outlined, color: colorScheme.onSurfaceVariant, size: 40)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  item.title,
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final actorImageWidget = CachedNetworkImage(
      imageUrl: widget.profileUrl, height: 120, width: 80, fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: colorScheme.surfaceVariant, height: 120, width: 80),
      errorWidget: (context, url, error) => Container(color: colorScheme.surfaceVariant, height: 120, width: 80, child: Icon(Icons.person_rounded, size: 40, color: colorScheme.onSurfaceVariant)),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAllActorData,
        color: colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100.0, pinned: true, stretch: true, automaticallyImplyLeading: false,
              backgroundColor: colorScheme.surface.withOpacity(0.85), elevation: 0,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(widget.actorName, style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                    background: Container(color: Colors.transparent),
                  ),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withOpacity(0.6), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      color: colorScheme.onSurfaceVariant,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Actor Details Section
            SliverToBoxAdapter(
              child: _isLoadingDetails
                  ? _buildShimmerActorDetails()
                  : _hasDetailsError
                  ? ErrorDisplayWidget(
                message: 'Failed to load actor details. Please try again.',
                onRetry: _loadActorDetails,
                icon: Icons.person_off_rounded,
              )
                  : Card(
                elevation: 1, margin: const EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: widget.heroTag != null ? Hero(tag: widget.heroTag!, child: actorImageWidget) : actorImageWidget),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.actorName, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (_birthday != null)
                                  Text('Born: ${DateFormat.yMMMd().format(_birthday!)}', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                                if (_placeOfBirth != null && _placeOfBirth!.isNotEmpty)
                                  Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('Place of Birth: $_placeOfBirth', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_biography != null && _biography!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(color: colorScheme.outlineVariant, height: 1),
                        const SizedBox(height: 12),
                        Text('Biography', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final TextPainter textPainter = TextPainter(
                              text: TextSpan(
                                text: _biography,
                                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
                              ),
                              maxLines: _isBiographyExpanded ? null : 4,
                              textDirection: ui.TextDirection.ltr, // Use ui.TextDirection.ltr
                            )..layout(maxWidth: constraints.maxWidth);

                            // Only update _isBiographyOverflowing if the layout has changed or it's the first build
                            if (_isBiographyOverflowing != textPainter.didExceedMaxLines) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _isBiographyOverflowing = textPainter.didExceedMaxLines;
                                  });
                                }
                              });
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _biography!,
                                  key: _biographyTextKey, // Assign key to the Text widget
                                  maxLines: _isBiographyExpanded ? null : 4,
                                  overflow: _isBiographyExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
                                ),
                                if (_isBiographyOverflowing && !_isBiographyExpanded)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _isBiographyExpanded = true;
                                        });
                                      },
                                      child: Text('Read More', style: TextStyle(color: colorScheme.primary)),
                                    ),
                                  ),
                                if (_isBiographyExpanded && _isBiographyOverflowing)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _isBiographyExpanded = false;
                                        });
                                      },
                                      child: Text('Show Less', style: TextStyle(color: colorScheme.primary)),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // "Known For" Section
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text('Known For', style: textTheme.titleLarge))),
            SliverToBoxAdapter(
              child: _isLoadingKnownFor
                  ? _buildShimmerHorizontalList()
                  : _hasKnownForError
                  ? ErrorDisplayWidget(
                message: 'Failed to load "Known For" titles. Please try again.',
                onRetry: _loadKnownFor,
                icon: Icons.person_off_rounded,
              )
                  : _knownForItems.isEmpty
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('No specific known for titles found.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
              )
                  : SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _knownForItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  itemBuilder: (context, index) {
                    final item = _knownForItems[index];
                    return _buildKnownForItemCard(item, context).animate().fadeIn(duration: 300.ms, delay: (75 * index).ms).slideX(begin: 0.2, duration: 250.ms, delay: (75 * index).ms);
                  },
                ),
              ),
            ),

            // "Filmography" Section Header with Sort Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filmography', style: textTheme.titleLarge),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isLoadingFullFilmography && _displayedFilmographyItems.isNotEmpty)
                          Text('Sorted by: ${_getSortLabel(_sortBy)}', style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.sort_rounded, size: 24),
                          color: colorScheme.onSurfaceVariant,
                          tooltip: 'Sort Filmography',
                          onPressed: _showSortOptions,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Paginated Filmography Content List
            if (_isLoadingFullFilmography && _displayedFilmographyItems.isEmpty)
              SliverFillRemaining(child: _buildShimmerFilmographyList(), hasScrollBody: false)
            else if (_hasFilmographyError && _displayedFilmographyItems.isEmpty)
              SliverFillRemaining(
                child: ErrorDisplayWidget(
                  message: 'Failed to load filmography. Please try again.',
                  onRetry: _fetchAndDisplayFullFilmography,
                  icon: Icons.list_alt_rounded, // Changed from Icons.view_list_off_rounded
                ),
                hasScrollBody: false,
              )
            else if (_displayedFilmographyItems.isEmpty && !_isLoadingFullFilmography)
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40.0), child: Center(child: Text('No filmography available for current sort.', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)))))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final mediaItem = _displayedFilmographyItems[index];
                      final filmographyHeroTag = 'filmography_poster_${mediaItem.id}_${widget.actorId}';
                      return Card(
                        elevation: 1, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), color: colorScheme.surfaceContainer, clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DetailsScreen(item: mediaItem, heroTag: filmographyHeroTag)));
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: filmographyHeroTag,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: mediaItem.posterUrl, height: 100, width: 70, fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(color: colorScheme.surfaceVariant, height: 100, width: 70),
                                      errorWidget: (context, url, error) => Container(color: colorScheme.surfaceVariant, height: 100, width: 70, child: Icon(Icons.image_not_supported_rounded, size: 24, color: colorScheme.onSurfaceVariant)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mediaItem.title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (mediaItem.year.isNotEmpty) Text(mediaItem.year, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                          if (mediaItem.year.isNotEmpty && mediaItem.rating > 0) Text(' • ', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                                          if (mediaItem.rating > 0) ...[
                                            Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                            const SizedBox(width: 2),
                                            Text(mediaItem.rating.toStringAsFixed(1), style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                                          ],
                                        ],
                                      ),
                                      if (mediaItem.character != null && mediaItem.character!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('as ${mediaItem.character}', style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant.withOpacity(0.8))),
                                      ],
                                      if (mediaItem.genres.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Wrap(spacing: 6, runSpacing: 4, children: mediaItem.genres.take(2).map((genre) => Chip(label: Text(genre), labelStyle: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer), backgroundColor: colorScheme.secondaryContainer.withOpacity(0.7), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0), visualDensity: VisualDensity.compact, side: BorderSide.none)).toList()),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: (30 * index).ms).slideX(begin: 0.05, duration: 200.ms, delay: (30 * index).ms);
                    },
                    childCount: _displayedFilmographyItems.length,
                  ),
                ),

            // Load More Button for Filmography
            SliverToBoxAdapter(
              child: _canLoadMoreFilmography
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: _isLoadingMoreFilmography
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Load More'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _loadMoreFilmographyItems();
                  },
                ),
              )
                  : const SizedBox(height: 16),
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16)),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortOption) {
    switch (sortOption) {
      case 'popularity': return 'Popularity';
      case 'vote_average': return 'Rating';
      case 'release_date': return 'Release Date';
      default: return 'Popularity';
    }
  }
}