import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/media_item.dart';
import '../providers/library_provider.dart';
import 'details_screen.dart';
import '../services/tmdb_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String sortBy = 'date_added'; // Default sorting option

  final List<LibraryStatus> _libraryStatuses = [
    LibraryStatus.watching,
    LibraryStatus.wantToWatch,
    LibraryStatus.completed,
    LibraryStatus.onHold,
    LibraryStatus.dropped,
  ];

  final TmdbService _tmdbService = TmdbService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _libraryStatuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MediaItem> _getSortedItems(List<MediaItem> items) {
    final sortedItems = List<MediaItem>.from(items);
    if (sortBy == 'rating') {
      sortedItems.sort((a, b) {
        double ratingA = a.userRating ?? a.rating;
        double ratingB = b.userRating ?? b.rating;
        return ratingB.compareTo(ratingA);
      });
    } else if (sortBy == 'title') {
      sortedItems.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return sortedItems;
  }

  void _showSortOptions() {
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
                child: Text(
                  'Sort Library By',
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 8),
              _buildSortOption(
                title: 'Date Added',
                icon: Icons.calendar_today_rounded,
                value: 'date_added',
              ),
              _buildSortOption(
                title: 'Rating',
                icon: Icons.star_border_rounded,
                value: 'rating',
              ),
              _buildSortOption(
                title: 'Title',
                icon: Icons.sort_by_alpha_rounded,
                value: 'title',
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() {
            sortBy = value;
          });
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
              Icon(
                isSelected ? (value == 'rating' ? Icons.star_rounded : (value == 'title' ? Icons.sort_by_alpha_rounded : Icons.event_available_rounded)) : icon,
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

  Widget _buildLibraryTab(List<MediaItem> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/empty.json', width: 200, height: 200),
            const SizedBox(height: 16),
            Text(
              'No items in this category.',
              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final heroTag = 'library_poster_${item.id}_${item.isMovie}';

        // --- Start of Trailing Actions Logic ---
        List<Widget> trailingActions = [];

        // For "Watching" items, primarily show increment, and decrement if progress exists
        if (item.libraryStatus == LibraryStatus.watching) {
          // Decrement button (only visible if current progress is greater than 0)
          if ((item.currentProgress ?? 0) > 0) {
            trailingActions.add(
              IconButton(
                icon: Icon(Icons.remove_circle_outline_rounded, color: colorScheme.primary),
                tooltip: 'Decrement progress',
                onPressed: () async {
                  int? totalEpisodes;
                  if (!item.isMovie) {
                    totalEpisodes = await _tmdbService.getTvShowTotalEpisodes(item.id);
                  } else {
                    totalEpisodes = 1;
                  }
                  if (totalEpisodes == null || totalEpisodes <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not determine total episodes/movie length to decrement progress.')),
                      );
                    }
                    return;
                  }
                  libraryProvider.updateProgress(item.id, totalEpisodes, increment: false);
                },
              ),
            );
          }

          // Increment button (always visible for watching items)
          trailingActions.add(
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary),
              tooltip: 'Mark progress',
              onPressed: () async {
                int? totalEpisodes;
                if (!item.isMovie) {
                  totalEpisodes = await _tmdbService.getTvShowTotalEpisodes(item.id);
                } else {
                  totalEpisodes = 1;
                }

                if (totalEpisodes == null || totalEpisodes <= 0) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not determine total episodes/movie length to update progress.')),
                    );
                  }
                  return;
                }

                int currentProgress = item.currentProgress ?? 0;
                if (currentProgress < totalEpisodes) {
                  libraryProvider.updateProgress(item.id, totalEpisodes, increment: true);

                  if ((currentProgress + 1) == totalEpisodes) {
                    _showRatingDialog(context, item, libraryProvider, item.userRating ?? 5.0, item.note, (rating, note) {
                      libraryProvider.updateItemStatus(item, LibraryStatus.completed, userRating: rating, progress: item.isMovie ? 1 : null, note: note);
                    });
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.title} is already marked as completed or at max progress.')),
                    );
                  }
                }
              },
            ),
          );
        } else if (item.libraryStatus == LibraryStatus.completed) {
          // Rating button only for completed items
          trailingActions.add(
            IconButton(
              icon: Icon(Icons.star_half_rounded, color: colorScheme.primary),
              tooltip: 'Change rating',
              onPressed: () {
                _showRatingDialog(context, item, libraryProvider, item.userRating ?? 5.0, item.note, (rating, note) {
                  libraryProvider.updateUserRating(item.id, rating);
                  libraryProvider.updateItemStatus(item, item.libraryStatus, note: note); // Update note
                });
              },
            ),
          );
        }
        // --- End of Trailing Actions Logic ---


        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          clipBehavior: Clip.antiAlias,
          child: InkWell( // Use InkWell for splash effect on long press
            onLongPress: () => _showEditItemDialog(context, item, libraryProvider),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              leading: Hero(
                tag: heroTag,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: item.posterUrl,
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60, height: 90,
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60, height: 90,
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      child: Icon(Icons.broken_image_outlined, color: colorScheme.onSurfaceVariant, size: 30),
                    ),
                  ),
                ),
              ),
              title: Text(
                item.title,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '${item.year} • ${item.genres.take(2).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  if (item.libraryStatus == LibraryStatus.completed && item.userRating != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: _getRatingColor(item.userRating!, colorScheme), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          item.userRating!.toStringAsFixed(1),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else if (item.libraryStatus == LibraryStatus.watching)
                    FutureBuilder<int?>(
                      future: item.isMovie
                          ? Future.value(1)
                          : _tmdbService.getTvShowTotalEpisodes(item.id),
                      builder: (context, snapshot) {
                        String progressText = "Not Started";
                        if (item.isMovie) {
                          if (item.currentProgress != null && item.currentProgress! > 0) {
                            progressText = "${item.currentProgress}/1";
                          } else {
                            progressText = "0/1";
                          }
                        } else { // It's a TV show
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            progressText = "Loading progress...";
                          } else if (snapshot.hasError) {
                            progressText = "Error loading total episodes";
                          } else {
                            final int? totalEpisodes = snapshot.data;
                            if (item.currentProgress != null && item.currentProgress! > 0) {
                              progressText = "${item.currentProgress}/${totalEpisodes ?? '?'}";
                            } else if (totalEpisodes != null) {
                              progressText = "0/${totalEpisodes}";
                            }
                          }
                        }
                        return Text(
                          progressText,
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                        );
                      },
                    )
                  else if (item.libraryStatus == LibraryStatus.onHold)
                      Text('On Hold', style: textTheme.bodySmall?.copyWith(color: Colors.orange))
                    else if (item.libraryStatus == LibraryStatus.dropped)
                        Text('Dropped', style: textTheme.bodySmall?.copyWith(color: colorScheme.error))
                      else if (item.libraryStatus == LibraryStatus.wantToWatch)
                          Text('Want to Watch', style: textTheme.bodySmall?.copyWith(color: colorScheme.secondary)),
                  if (item.note != null && item.note!.isNotEmpty) // Display the note in the subtitle
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Note: ${item.note}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: trailingActions,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailsScreen(item: item, heroTag: heroTag),
                  ),
                );
              },
            ),
          ),
        ).animate()
            .fadeIn(duration: 400.ms, delay: (50 * index).ms)
            .slideX(begin: 0.2, end: 0, duration: 300.ms, delay: (50 * index).ms, curve: Curves.easeOutCubic);
      },
    );
  }

  void _showRatingDialog(BuildContext context, MediaItem item, LibraryProvider libraryProvider, double initialRating, String? initialNote, Function(double, String?) onRatingSubmitted) {
    double _dialogRating = initialRating > 0 ? initialRating : 5.0;
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
              return SingleChildScrollView( // Allow scrolling for notes
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Your rating: ${_dialogRating.toStringAsFixed(1)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Slider(
                      value: _dialogRating,
                      min: 0.0,
                      max: 10.0,
                      divisions: 20,
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
                ),
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


  // New: Show Edit Item Dialog
  void _showEditItemDialog(BuildContext context, MediaItem item, LibraryProvider libraryProvider) async {
    LibraryStatus _selectedStatus = item.libraryStatus;
    double _dialogUserRating = item.userRating ?? 5.0;
    int _dialogCurrentProgress = item.currentProgress ?? 0;
    TextEditingController _noteController = TextEditingController(text: item.note);

    // Fetch total episodes if it's a TV show and not already set
    if (!item.isMovie && (item.totalEpisodes == null || item.totalEpisodes == 0)) {
      int? fetchedTotalEpisodes = await _tmdbService.getTvShowTotalEpisodes(item.id);
      if (fetchedTotalEpisodes != null) {
        item.totalEpisodes = fetchedTotalEpisodes; // Update item in place for current dialog session
      }
    }
    final int actualTotalEpisodes = item.isMovie ? 1 : (item.totalEpisodes ?? 1); // Ensure totalEpisodes is valid

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows content to take full height
      backgroundColor: Colors.transparent,
      elevation: 0,
      useSafeArea: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, MediaQuery.of(context).viewInsets.bottom + 16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28.0),
                    topRight: Radius.circular(28.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Edit "${item.title}" in Library',
                        style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      Text('Status', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Column(
                        children: LibraryStatus.values.where((s) => s != LibraryStatus.none).map((status) {
                          String label = status.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
                          label = label.substring(0, 1).toUpperCase() + label.substring(1);
                          return RadioListTile<LibraryStatus>(
                            title: Text(label, style: textTheme.bodyLarge),
                            value: status,
                            groupValue: _selectedStatus,
                            onChanged: (LibraryStatus? newValue) {
                              setState(() {
                                _selectedStatus = newValue!;
                                if (_selectedStatus == LibraryStatus.completed) {
                                  _dialogCurrentProgress = item.isMovie ? 1 : actualTotalEpisodes;
                                } else if (_selectedStatus != LibraryStatus.watching) {
                                  _dialogCurrentProgress = 0; // Reset progress if not watching/completed
                                }
                              });
                            },
                            activeColor: colorScheme.primary,
                            dense: true,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      if (_selectedStatus == LibraryStatus.watching) ...[
                        Text('Progress (Episodes)', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline_rounded, color: colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  _dialogCurrentProgress = (_dialogCurrentProgress - 1).clamp(0, actualTotalEpisodes);
                                });
                              },
                            ),
                            Expanded(
                              child: Slider(
                                value: _dialogCurrentProgress.toDouble(),
                                min: 0,
                                max: actualTotalEpisodes.toDouble(),
                                divisions: actualTotalEpisodes > 0 ? actualTotalEpisodes : 1,
                                label: _dialogCurrentProgress.toString(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _dialogCurrentProgress = newValue.toInt();
                                  });
                                },
                                activeColor: colorScheme.primary,
                                inactiveColor: colorScheme.onSurfaceVariant.withOpacity(0.3),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  _dialogCurrentProgress = (_dialogCurrentProgress + 1).clamp(0, actualTotalEpisodes);
                                });
                              },
                            ),
                          ],
                        ),
                        Center(
                          child: Text(
                            item.isMovie ?
                            'Movie Progress: ${_dialogCurrentProgress}/1' :
                            'Episodes: ${_dialogCurrentProgress}/${actualTotalEpisodes}',
                            style: textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_selectedStatus == LibraryStatus.completed) ...[
                        Text('Your Rating', style: textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Rating: ${_dialogUserRating.toStringAsFixed(1)} / 10.0', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                        Slider(
                          value: _dialogUserRating,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          label: _dialogUserRating.toStringAsFixed(1),
                          onChanged: (newValue) {
                            setState(() {
                              _dialogUserRating = newValue;
                            });
                          },
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.onSurfaceVariant.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Text('Note (Optional)', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField( // Text field for editing the note
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Add a personal note about this item...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                libraryProvider.removeFromLibrary(item.id);
                                _tmdbService.invalidateTvDetailsCache(item.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.title} removed from your library'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                  Navigator.pop(context); // Close dialog
                                }
                              },
                              icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
                              label: Text('Remove', style: textTheme.labelLarge?.copyWith(color: colorScheme.error)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: colorScheme.error),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                libraryProvider.updateItemStatus(
                                  item,
                                  _selectedStatus,
                                  userRating: _selectedStatus == LibraryStatus.completed ? _dialogUserRating : null,
                                  progress: _selectedStatus == LibraryStatus.watching || _selectedStatus == LibraryStatus.completed ? _dialogCurrentProgress : null,
                                  note: _noteController.text.isEmpty ? null : _noteController.text, // Pass the updated note
                                );
                                Navigator.pop(context); // Close dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.title} updated!'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Padding below buttons
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Color _getRatingColor(double rating, ColorScheme colorScheme) {
    if (rating >= 7.5) return Colors.green.shade400;
    if (rating >= 6.0) return Colors.amber.shade600;
    if (rating >= 4.0) return Colors.orange.shade500;
    return colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Library', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sort_rounded, size: 24),
                    color: colorScheme.onSurfaceVariant,
                    tooltip: 'Sort by',
                    onPressed: _showSortOptions,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          isScrollable: true,
          tabs: _libraryStatuses.map((status) {
            String label = status.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ');
            label = label.substring(0, 1).toUpperCase() + label.substring(1);
            return Tab(text: label);
          }).toList(),
        ),
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: _libraryStatuses.map((status) {
              return _buildLibraryTab(_getSortedItems(libraryProvider.getItemsByStatus(status)));
            }).toList(),
          );
        },
      ),
    );
  }
}