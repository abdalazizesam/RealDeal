import 'package:flutter/material.dart';

enum LibraryStatus {
  none,
  watching,
  wantToWatch,
  completed,
  onHold,
  dropped,
}

class MediaItem {
  final int id;
  final String title;
  final String overview;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final String year;
  final List<String> genres;
  final bool isMovie;
  final String? character;

  LibraryStatus libraryStatus;
  int? currentProgress; // For tracking episodes (TV) or movie completion (0 or 1 for movies)
  double? userRating; // User's rating for completed items (0.0 to 10.0)
  int? totalEpisodes; // Total episodes for TV shows, or 1 for movies
  String? note; // User's note for the item

  MediaItem({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.year,
    required this.genres,
    required this.isMovie,
    this.character,

    this.libraryStatus = LibraryStatus.none,
    this.currentProgress,
    this.userRating,
    this.totalEpisodes,
    this.note,
  });

  factory MediaItem.fromMovieJson(Map<String, dynamic> json, Map<int, String> genreMap, {String? character}) {
    String year = '';
    if (json['release_date'] != null && json['release_date'].toString().isNotEmpty) {
      year = json['release_date'].toString().split('-')[0];
    }

    List<String> genres = [];
    if (json['genre_ids'] != null) {
      genres = (json['genre_ids'] as List)
          .map((id) => genreMap[id] ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    return MediaItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown',
      overview: json['overview'] ?? 'No description available',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : 'https://via.placeholder.com/500x750?text=No+Image',
      backdropUrl: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w780${json['backdrop_path']}'
          : 'https://via.placeholder.com/780x439?text=No+Image',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      isMovie: true,
      character: character ?? json['character'],
      totalEpisodes: 1, // Movies have 1 "episode" for progress tracking
    );
  }

  factory MediaItem.fromTvJson(Map<String, dynamic> json, Map<int, String> genreMap, {String? character}) {
    String year = '';
    if (json['first_air_date'] != null && json['first_air_date'].toString().isNotEmpty) {
      year = json['first_air_date'].toString().split('-')[0];
    }

    List<String> genres = [];
    if (json['genre_ids'] != null) {
      genres = (json['genre_ids'] as List)
          .map((id) => genreMap[id] ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }

    return MediaItem(
      id: json['id'] ?? 0,
      title: json['name'] ?? 'Unknown',
      overview: json['overview'] ?? 'No description available',
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : 'https://via.placeholder.com/500x750?text=No+Image',
      backdropUrl: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w780${json['backdrop_path']}'
          : 'https://via.placeholder.com/780x439?text=No+Image',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      isMovie: false,
      character: character ?? json['character'],
      totalEpisodes: json['number_of_episodes'], // New: Assign number_of_episodes
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'rating': rating,
      'year': year,
      'genres': genres,
      'isMovie': isMovie,
      'character': character,
      'libraryStatus': libraryStatus.name, // Store as string
      'currentProgress': currentProgress,
      'userRating': userRating,
      'totalEpisodes': totalEpisodes, // Store total episodes
      'note': note, // Store note
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      title: json['title'],
      overview: json['overview'],
      posterUrl: json['posterUrl'],
      backdropUrl: json['backdropUrl'],
      rating: json['rating'],
      year: json['year'],
      genres: List<String>.from(json['genres']),
      isMovie: json['isMovie'],
      character: json['character'],
      libraryStatus: LibraryStatus.values.firstWhere(
              (e) => e.name == json['libraryStatus'], // Use .name to match string
          orElse: () => LibraryStatus.none),
      currentProgress: json['currentProgress'],
      userRating: json['userRating']?.toDouble(), // Ensure it's a double
      totalEpisodes: json['totalEpisodes'], // New: Read total episodes
      note: json['note'], // Read note
    );
  }
}

// Extension for easy copying with new values
extension MediaItemCopyWith on MediaItem {
  MediaItem copyWith({
    int? id,
    String? title,
    String? overview,
    String? posterUrl,
    String? backdropUrl,
    double? rating,
    String? year,
    List<String>? genres,
    bool? isMovie,
    String? character,
    LibraryStatus? libraryStatus,
    int? currentProgress,
    double? userRating,
    int? totalEpisodes,
    String? note,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      isMovie: isMovie ?? this.isMovie,
      character: character ?? this.character,
      libraryStatus: libraryStatus ?? this.libraryStatus,
      currentProgress: currentProgress ?? this.currentProgress,
      userRating: userRating ?? this.userRating,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      note: note ?? this.note,
    );
  }
}