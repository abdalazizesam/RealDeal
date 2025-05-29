import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../providers/library_provider.dart';
import '../services/tmdb_service.dart';
import '../widgets/youtube_player_widget.dart';
import 'actor_details_screen.dart';

class DetailsScreen extends StatefulWidget {
  final MediaItem item;
  final String? heroTag;

  const DetailsScreen({Key? key, required this.item, this.heroTag}) : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final TmdbService _tmdbService = TmdbService();
  String? _trailerUrl;
  bool _isLoadingTrailer = true;
  String? _duration;
  bool _isLoadingDetails = true;
  List<Map<String, dynamic>> _cast = [];
  bool _isLoadingCast = true;
  List<MediaItem> _similarContent = [];
  bool _isLoadingSimilar = true;

  Map<String, dynamic>? _watchProviders;
  bool _isLoadingProviders = true;

  String? _originalLanguage;
  String? _originalTitle; // New field
  String? _status; // New field
  int? _budget;
  int? _revenue;
  String? _director;
  List<String> _writers = [];
  List<String> _creators = [];

  @override
  void initState() {
    super.initState();
    _loadAllDetails();
  }

  Future<void> _loadAllDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTrailer = true;
      _isLoadingDetails = true;
      _isLoadingCast = true;
      _isLoadingSimilar = true;
      _isLoadingProviders = true;
      _duration = null;
      _trailerUrl = null;
      _originalLanguage = null;
      _originalTitle = null; // Reset
      _status = null; // Reset
      _budget = null;
      _revenue = null;
      _director = null;
      _writers = [];
      _creators = [];
    });

    try {
      await Future.wait([
        _loadTrailerAndDurationAndMoreDetails(),
        _loadCast(),
        _loadSimilarContent(),
        _loadWatchProviders(),
        _loadCrewDetails(),
      ]);
    } catch (e) {
      if (mounted) {
        print('Error loading details: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load some details: ${e.toString()}', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrailer = false;
          _isLoadingDetails = false;
          _isLoadingCast = false;
          _isLoadingSimilar = false;
          _isLoadingProviders = false;
        });
      }
    }
  }

  Future<void> _loadTrailerAndDurationAndMoreDetails() async {
    try {
      final trailer = await _tmdbService.getTrailerUrl(widget.item.id, widget.item.isMovie);
      if (mounted) {
        setState(() {
          _trailerUrl = trailer;
        });
      }

      Map<String, dynamic> details;
      if (widget.item.isMovie) {
        details = await _tmdbService.getMovieDetails(widget.item.id);
        if (mounted) {
          setState(() {
            _budget = details['budget'];
            _revenue = details['revenue'];
            _originalLanguage = details['original_language'];
            _originalTitle = details['original_title'];
            _status = details['status'];
          });
        }
      } else {
        details = await _tmdbService.getTVShowDetails(widget.item.id);
        if (mounted) {
          setState(() {
            _originalLanguage = details['original_language'];
            _status = details['status'];
          });
        }
      }
      if (mounted) {
        setState(() {
          _duration = details['duration'];
        });
      }
    } catch (e) {
      print('Error loading trailer/duration/details: $e');
    }
  }

  Future<void> _loadCast() async {
    try {
      final castData = await _tmdbService.getCast(widget.item.id, widget.item.isMovie);
      if (mounted) {
        setState(() {
          _cast = castData;
        });
      }
    } catch (e) {
      print('Error loading cast: $e');
    }
  }

  Future<void> _loadSimilarContent() async {
    try {
      List<MediaItem> similarData;
      if (widget.item.isMovie) {
        similarData = await _tmdbService.getSimilarMovies(widget.item.id);
      } else {
        similarData = await _tmdbService.getSimilarTVShows(widget.item.id);
      }
      if (mounted) {
        setState(() {
          _similarContent = similarData;
        });
      }
    } catch (e) {
      print('Error loading similar content: $e');
    }
  }

  Future<void> _loadWatchProviders() async {
    try {
      final providers = await _tmdbService.getWatchProviders(widget.item.id, widget.item.isMovie);
      if (mounted) {
        setState(() {
          _watchProviders = providers;
        });
      }
    } catch (e) {
      print('Error loading watch providers: $e');
    }
  }

  Future<void> _loadCrewDetails() async {
    try {
      final crew = await _tmdbService.getCrewDetails(widget.item.id, widget.item.isMovie);
      if (mounted) {
        final List<String>? directorList = crew['director'];
        String? foundDirector;
        if (directorList != null && directorList.isNotEmpty) {
          foundDirector = directorList.firstWhere(
                (element) => element.isNotEmpty,
            orElse: () => '',
          );
        }
        _director = foundDirector?.isNotEmpty == true ? foundDirector : null;

        _writers = (crew['writers'] as List<String>?)?.where((element) => element.isNotEmpty).toList() ?? [];
        _creators = (crew['creators'] as List<String>?)?.where((element) => element.isNotEmpty).toList() ?? [];

        setState(() {
          // State variables are updated above, just need to trigger rebuild
        });
      }
    } catch (e) {
      print('Error loading crew details: $e');
    }
  }

  Widget _buildShimmerPlaceholder({double height = 200, int itemCount = 5}) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Card(
            elevation: 1.0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            margin: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
              highlightColor: colorScheme.surfaceVariant.withOpacity(0.2),
              child: SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(color: Colors.grey[800]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        height: 12,
                        width: 100,
                        color: Colors.grey[800],
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

  Widget _buildShimmerCastPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: colorScheme.surfaceVariant.withOpacity(0.5),
            highlightColor: colorScheme.surfaceVariant.withOpacity(0.2),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[800],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10, width: 60, color: Colors.grey[800],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8, width: 70, color: Colors.grey[800],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(int? amount) {
    if (amount == null || amount <= 0) return 'N/A';
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _getLanguageName(String? code) {
    if (code == null || code.isEmpty) return 'N/A';
    try {
      final locale = Locale(code);
      // Use displayLanguage to get the full name
      String languageName = locale.toLanguageTag(); // default behavior for unknown locales
      if (languageName == code) {
        // Attempt to convert if toLanguageTag is just the code
        switch (code.toLowerCase()) {
          case 'en': return 'English';
          case 'fr': return 'French';
          case 'es': return 'Spanish';
          case 'de': return 'German';
          case 'ja': return 'Japanese';
          case 'ko': return 'Korean';
          case 'zh': return 'Chinese';
          case 'ar': return 'Arabic';
          case 'hi': return 'Hindi';
          case 'pt': return 'Portuguese';
          case 'ru': return 'Russian';
          case 'it': return 'Italian';
        // Add more as needed
          default: return code.toUpperCase();
        }
      }
      return languageName;
    } catch (e) {
      return code.toUpperCase();
    }
  }

  Future<void> _launchWatchProviderUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
      }
    }
  }

  // New method to show library status options
  void _showLibraryStatusOptions(BuildContext context, MediaItem item, LibraryProvider libraryProvider, LibraryStatus currentStatus) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      builder: (context) {
        // Using StatefulBuilder to allow the dialog to rebuild its content
        // For instance, if you wanted to change the UI based on selection within the dialog itself
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return BackdropFilter(
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
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text('Add to Library', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                    ),
                    const SizedBox(height: 8),
                    // Build options for each LibraryStatus
                    ...LibraryStatus.values.where((status) => status != LibraryStatus.none).map((status) {
                      return _buildStatusOption(
                        context,
                        status,
                        currentStatus,
                            (selectedStatus) {
                          Navigator.pop(context); // Close bottom sheet
                          if (selectedStatus == LibraryStatus.completed) {
                            // If completed, show rating dialog
                            _showRatingDialog(context, item, libraryProvider, item.userRating ?? 5.0, item.note, (rating, note) {
                              libraryProvider.updateItemStatus(item, selectedStatus, userRating: rating, progress: item.isMovie ? 1 : null, note: note);
                            });
                          } else {
                            libraryProvider.updateItemStatus(item, selectedStatus);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.title} moved to ${selectedStatus.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ').toLowerCase()}'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      );
                    }).toList(),
                    // Option to remove from library if already present
                    if (currentStatus != LibraryStatus.none)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextButton.icon(
                          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                          label: Text('Remove from Library', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
                          onPressed: () {
                            Navigator.pop(context); // Close bottom sheet
                            libraryProvider.removeFromLibrary(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.title} removed from your library'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget to build a single status option in the bottom sheet
  Widget _buildStatusOption(BuildContext context, LibraryStatus status, LibraryStatus currentStatus, ValueChanged<LibraryStatus> onSelected) {
    final bool isSelected = currentStatus == status;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Format enum name for display (e.g., "wantToWatch" -> "Want to Watch")
    String title = status.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
    title = title.substring(0, 1).toUpperCase() + title.substring(1);

    IconData icon;
    switch (status) {
      case LibraryStatus.watching: icon = Icons.play_circle_outline_rounded; break;
      case LibraryStatus.wantToWatch: icon = Icons.playlist_add_rounded; break;
      case LibraryStatus.completed: icon = Icons.check_circle_outline_rounded; break;
      case LibraryStatus.onHold: icon = Icons.pause_circle_outline_rounded; break;
      case LibraryStatus.dropped: icon = Icons.cancel_outlined; break;
      case LibraryStatus.none: icon = Icons.help_outline; break; // Should not be reached
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(status),
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
              Icon(
                icon,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog to allow user to rate a completed item
  void _showRatingDialog(BuildContext context, MediaItem item, LibraryProvider libraryProvider, double initialRating, String? initialNote, Function(double, String?) onRatingSubmitted) {
    double _dialogRating = initialRating > 0 ? initialRating : 5.0; // Default rating if none exists
    TextEditingController _noteController = TextEditingController(text: initialNote);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text('Rate ${item.title}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Your rating: ${_dialogRating.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Slider(
                    value: _dialogRating,
                    min: 0.0,
                    max: 10.0,
                    divisions: 20, // 0.5 increments
                    label: _dialogRating.toStringAsFixed(1),
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    onChanged: (newValue) {
                      setState(() {
                        _dialogRating = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Add a note (optional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                      ),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      floatingLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                onRatingSubmitted(_dialogRating, _noteController.text.isEmpty ? null : _noteController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context); // Get the provider
    final MediaItem? currentItemInLibrary = libraryProvider.getItemFromLibrary(widget.item.id);
    final LibraryStatus currentLibraryStatus = currentItemInLibrary?.libraryStatus ?? LibraryStatus.none;
    final String? itemNote = currentItemInLibrary?.note;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              centerTitle: true,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: widget.heroTag ?? 'backdrop_${widget.item.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.item.backdropUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: colorScheme.surfaceVariant),
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceVariant,
                        child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant, size: 48),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      color: colorScheme.onSurface,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
            // Removed actions from AppBar
            actions: const [],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: widget.heroTag ?? 'poster_detail_${widget.item.id}',
                      child: Card(
                        elevation: 2.0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: widget.item.posterUrl,
                          height: 180,
                          width: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceVariant,
                            height: 180, width: 120,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceVariant,
                            height: 180, width: 120,
                            child: Icon(Icons.movie_creation_outlined, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title,
                            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rate_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                widget.item.rating == 0.0 ? 'Unrated' : '${widget.item.rating.toStringAsFixed(1)}/10',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 12),
                              Text('(${widget.item.year})', style: textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (_isLoadingDetails)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                              ),
                            )
                          else if (_duration != null && _duration!.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, color: colorScheme.onSurfaceVariant, size: 18),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _duration!,
                                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 32,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.item.genres.length,
                              itemBuilder: (context, index) {
                                final genre = widget.item.genres[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text(genre),
                                    labelStyle: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer),
                                    backgroundColor: colorScheme.secondaryContainer.withOpacity(0.7),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide.none,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Add to Library Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.tertiary.withOpacity(0.8), // Using tertiary color for this button
                        colorScheme.tertiaryContainer.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.tertiary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showLibraryStatusOptions(context, widget.item, libraryProvider, currentLibraryStatus);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_add_rounded, color: colorScheme.onTertiary, size: 28), // Changed icon and color
                            const SizedBox(width: 12),
                            Text(
                              currentLibraryStatus != LibraryStatus.none ? 'Update My Library' : 'Add to My Library',
                              style: textTheme.titleMedium?.copyWith(color: colorScheme.onTertiary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),


                if (_isLoadingTrailer)
                  Center(
                    child: SizedBox(
                      width: 48, height: 48,
                      child: CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
                    ),
                  )
                else if (_trailerUrl != null && _trailerUrl!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.primaryContainer.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => YoutubePlayerWidget(url: _trailerUrl!),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_circle_fill_rounded, color: colorScheme.onPrimary, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                'Watch Trailer',
                                style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                Text('Overview', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(widget.item.overview, style: textTheme.bodyMedium?.copyWith(height: 1.5)),

                if (itemNote != null && itemNote.isNotEmpty) ...[ // Display the user's note if available
                  const SizedBox(height: 16),
                  Text('Your Note', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        itemNote,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Text('More Details', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                _isLoadingDetails
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : Card(
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_originalLanguage != null && _originalLanguage!.isNotEmpty)
                          _buildDetailRow(context, Icons.language_rounded, 'Original Language', _getLanguageName(_originalLanguage)),
                        if (_originalTitle != null && _originalTitle!.isNotEmpty && widget.item.title != _originalTitle)
                          _buildDetailRow(context, Icons.title_rounded, 'Original Title', _originalTitle),
                        if (_status != null && _status!.isNotEmpty)
                          _buildDetailRow(context, Icons.info_outline_rounded, 'Status', _status),
                        if (widget.item.isMovie && _budget != null && _budget! > 0)
                          _buildDetailRow(context, Icons.attach_money_rounded, 'Budget', _formatCurrency(_budget)),
                        if (widget.item.isMovie && _revenue != null && _revenue! > 0)
                          _buildDetailRow(context, Icons.trending_up_rounded, 'Revenue', _formatCurrency(_revenue)),
                        if (_director != null && _director!.isNotEmpty)
                          _buildDetailRow(context, Icons.movie_creation_rounded, 'Director', _director!),
                        if (_writers.isNotEmpty)
                          _buildDetailRow(context, Icons.edit_note_rounded, 'Writer(s)', _writers.join(', ')),
                        if (!widget.item.isMovie && _creators.isNotEmpty)
                          _buildDetailRow(context, Icons.person_add_alt_rounded, 'Creator(s)', _creators.join(', ')),
                      ].expand((widget) => [widget, const SizedBox(height: 8)]).toList()..removeLast(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Where to Watch', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                _isLoadingProviders
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : (_watchProviders != null && _watchProviders!.isNotEmpty)
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_watchProviders!['flatrate'] != null)
                      _buildProviderSection(context, 'Stream', _watchProviders!['flatrate'], colorScheme, textTheme),
                    if (_watchProviders!['rent'] != null)
                      _buildProviderSection(context, 'Rent', _watchProviders!['rent'], colorScheme, textTheme),
                    if (_watchProviders!['buy'] != null)
                      _buildProviderSection(context, 'Buy', _watchProviders!['buy'], colorScheme, textTheme),
                    if (_watchProviders!['link'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextButton.icon(
                          icon: Icon(Icons.open_in_new_rounded, color: colorScheme.primary),
                          label: Text('View all options on TMDB', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                          onPressed: () => _launchWatchProviderUrl(_watchProviders!['link']),
                        ),
                      )
                  ],
                )
                    : Center(child: Text('No watch options found.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))),
                const SizedBox(height: 24),

                Text('Cast', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                _isLoadingCast
                    ? _buildShimmerCastPlaceholder()
                    : _cast.isEmpty
                    ? Center(child: Text('No cast information available.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)))
                    : SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cast.length,
                    itemBuilder: (context, index) {
                      final castMember = _cast[index];
                      final actorHeroTag = 'actor_${castMember['id']}';
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActorDetailsScreen(
                                actorName: castMember['name'] ?? '',
                                profileUrl: castMember['profileUrl'] ?? '',
                                actorId: castMember['id'] ?? 0,
                                heroTag: actorHeroTag,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Hero(
                                tag: actorHeroTag,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundImage: CachedNetworkImageProvider(castMember['profileUrl'] ?? ''),
                                  backgroundColor: colorScheme.surfaceVariant,
                                  child: (castMember['profileUrl'] == null || (castMember['profileUrl'] as String).contains('placeholder'))
                                      ? Icon(Icons.person, size: 40, color: colorScheme.onSurfaceVariant)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                castMember['name'] ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                castMember['character'] ?? '',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Text('Similar Content', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                _isLoadingSimilar
                    ? _buildShimmerPlaceholder()
                    : _similarContent.isEmpty
                    ? Center(child: Text('No similar content available.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)))
                    : SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _similarContent.length,
                    itemBuilder: (context, index) {
                      final item = _similarContent[index];
                      final similarHeroTag = 'similar_poster_${item.id}';
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(item: item, heroTag: similarHeroTag),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 1.0,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          margin: const EdgeInsets.only(right: 12),
                          child: SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Hero(
                                    tag: similarHeroTag,
                                    child: CachedNetworkImage(
                                      imageUrl: item.posterUrl,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      placeholder: (context, url) => Container(
                                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                                        child: Icon(Icons.movie_creation_outlined, color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty || value == 'N/A') return const SizedBox.shrink(); // Hide if no value
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(value, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSection(BuildContext context, String title, List<dynamic> providers, ColorScheme colorScheme, TextTheme textTheme) {
    final String? sectionLink = _watchProviders?['link'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface)),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              final logoPath = provider['logo_path'];
              final providerName = provider['provider_name'];

              if (logoPath == null) return const SizedBox.shrink();

              return GestureDetector(
                onTap: sectionLink != null ? () => _launchWatchProviderUrl(sectionLink) : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Tooltip(
                    message: providerName,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: 'https://image.tmdb.org/t/p/w92$logoPath',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: colorScheme.surfaceVariant),
                        errorWidget: (context, url, error) => Container(
                          color: colorScheme.surfaceVariant,
                          child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}