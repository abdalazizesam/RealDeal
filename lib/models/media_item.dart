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
  });

  factory MediaItem.fromMovieJson(Map<String, dynamic> json, Map<int, String> genreMap) {
    // Extract year from release_date (format: YYYY-MM-DD)
    String year = '';
    if (json['release_date'] != null && json['release_date'].toString().isNotEmpty) {
      year = json['release_date'].toString().split('-')[0];
    }

    // Get genre names from IDs
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
          ? 'https://image.tmdb.org/t/p/w500${json['backdrop_path']}'
          : 'https://via.placeholder.com/500x281?text=No+Image',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      isMovie: true,
      character: json['character'],
    );
  }

  factory MediaItem.fromTvJson(Map<String, dynamic> json, Map<int, String> genreMap) {
    // Extract year from first_air_date (format: YYYY-MM-DD)
    String year = '';
    if (json['first_air_date'] != null && json['first_air_date'].toString().isNotEmpty) {
      year = json['first_air_date'].toString().split('-')[0];
    }

    // Get genre names from IDs
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
          ? 'https://image.tmdb.org/t/p/w500${json['backdrop_path']}'
          : 'https://via.placeholder.com/500x281?text=No+Image',
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      year: year,
      genres: genres,
      isMovie: false,
      character: json['character'],
    );
  }

  // For converting to JSON for storage in SharedPreferences
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
    };
  }

  // For recreating from SharedPreferences JSON
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
    );
  }
}