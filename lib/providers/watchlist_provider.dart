import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class WatchlistProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  List<MediaItem> _watchlist = [];
  static const String _watchlistKey = 'watchlist';

  WatchlistProvider(this._prefs) {
    _loadWatchlist();
  }

  List<MediaItem> get watchlist => _watchlist;

  void _loadWatchlist() {
    final String? watchlistJson = _prefs.getString(_watchlistKey);
    if (watchlistJson != null) {
      try {
        final List<dynamic> decodedList = json.decode(watchlistJson);
        _watchlist = decodedList
            .map((item) => MediaItem.fromJson(item))
            .toList();
      } catch (e) {
        debugPrint('Error loading watchlist: $e');
        _watchlist = [];
      }
    }
  }

  Future<void> _saveWatchlist() async {
    final String encodedList = json.encode(
      _watchlist.map((item) => item.toJson()).toList(),
    );
    await _prefs.setString(_watchlistKey, encodedList);
  }

  void addToWatchlist(MediaItem item) {
    if (!isInWatchlist(item.id)) {
      _watchlist.add(item);
      _saveWatchlist();
      notifyListeners();
    }
  }

  void removeFromWatchlist(int id) {
    _watchlist.removeWhere((item) => item.id == id);
    _saveWatchlist();
    notifyListeners();
  }

  bool isInWatchlist(int id) {
    return _watchlist.any((item) => item.id == id);
  }

  List<MediaItem> getMoviesWatchlist() {
    return _watchlist.where((item) => item.isMovie).toList();
  }

  List<MediaItem> getTVShowsWatchlist() {
    return _watchlist.where((item) => !item.isMovie).toList();
  }
}