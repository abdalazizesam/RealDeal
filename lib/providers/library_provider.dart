import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class LibraryProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<MediaItem> _libraryItems = [];
  static const String _libraryKey = 'my_library';

  LibraryProvider(this._prefs) {
    _loadLibrary();
  }

  List<MediaItem> get libraryItems => _libraryItems;

  void _loadLibrary() {
    final String? libraryJson = _prefs.getString(_libraryKey);
    if (libraryJson != null) {
      try {
        final List<dynamic> decodedList = json.decode(libraryJson);
        _libraryItems = decodedList
            .map((item) => MediaItem.fromJson(item))
            .toList();
      } catch (e) {
        debugPrint('Error loading library: $e');
        _libraryItems = []; // Reset on error
      }
    }
  }

  Future<void> _saveLibrary() async {
    final String encodedList = json.encode(
      _libraryItems.map((item) => item.toJson()).toList(),
    );
    await _prefs.setString(_libraryKey, encodedList);
  }

  bool isInLibrary(int id) {
    return _libraryItems.any((item) => item.id == id);
  }

  MediaItem? getItemFromLibrary(int id) {
    try {
      return _libraryItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateItemStatus(MediaItem item, LibraryStatus newStatus, {double? userRating, int? progress, String? note}) {
    int index = _libraryItems.indexWhere((i) => i.id == item.id);
    MediaItem updatedItem = item;

    if (index != -1) {
      // Item exists, update its properties
      updatedItem = _libraryItems[index].copyWith(
        libraryStatus: newStatus,
        userRating: newStatus == LibraryStatus.completed ? userRating : null, // Only keep rating if completed
        currentProgress: newStatus == LibraryStatus.watching // Only keep progress if watching
            ? (progress ?? _libraryItems[index].currentProgress ?? 0)
            : (newStatus == LibraryStatus.completed ? (item.isMovie ? 1 : null) : null), // For completed movies, set progress to 1
        note: note,
      );
      _libraryItems[index] = updatedItem;
    } else {
      // New item, add it to the library
      updatedItem = item.copyWith(
        libraryStatus: newStatus,
        userRating: newStatus == LibraryStatus.completed ? userRating : null,
        currentProgress: newStatus == LibraryStatus.watching ? (progress ?? 0) : null,
        note: note,
      );
      _libraryItems.add(updatedItem);
    }
    _saveLibrary();
    notifyListeners();
  }

  void removeFromLibrary(int id) {
    _libraryItems.removeWhere((item) => item.id == id);
    _saveLibrary();
    notifyListeners();
  }

  // Methods to get items by their specific status
  List<MediaItem> getItemsByStatus(LibraryStatus status) {
    return _libraryItems.where((item) => item.libraryStatus == status).toList();
  }

  // Update progress for an item that is being watched
  void updateProgress(int id, int totalEpisodesOrMovieStatus, {bool increment = true}) {
    int index = _libraryItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      MediaItem item = _libraryItems[index];
      int currentProgress = item.currentProgress ?? 0;

      if (increment) {
        currentProgress++;
      } else {
        currentProgress--;
      }
      // Clamp progress to be within valid range
      currentProgress = currentProgress.clamp(0, item.isMovie ? 1 : totalEpisodesOrMovieStatus);

      // If item was in another status and progress is updated, move to Watching
      LibraryStatus newStatus = item.libraryStatus;
      if (currentProgress > 0 && item.libraryStatus != LibraryStatus.watching && item.libraryStatus != LibraryStatus.completed) {
        newStatus = LibraryStatus.watching;
      }

      _libraryItems[index] = item.copyWith(
        currentProgress: currentProgress,
        libraryStatus: newStatus,
      );

      _saveLibrary();
      notifyListeners();
    }
  }

  // Update user rating for a completed item
  void updateUserRating(int id, double rating) {
    int index = _libraryItems.indexWhere((item) => item.id == id);
    if (index != -1 && _libraryItems[index].libraryStatus == LibraryStatus.completed) {
      _libraryItems[index] = _libraryItems[index].copyWith(userRating: rating);
      _saveLibrary();
      notifyListeners();
    }
  }
}