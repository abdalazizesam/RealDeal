import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class TmdbService {
  // Replace with your TMDB API key
  final String apiKey = 'c77efa315e4a87ebcd95b283b83e7aad';
  final String baseUrl = 'https://api.themoviedb.org/3';

  // Genre maps
  final Map<int, String> movieGenres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Science Fiction',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  final Map<int, String> tvGenres = {
    10759: 'Action & Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    10762: 'Kids',
    9648: 'Mystery',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
    37: 'Western',
  };

  // Get popular movies
  Future<List<MediaItem>> getPopularMovies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/popular?api_key=$apiKey&language=en-US&page=1'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromMovieJson(json, movieGenres))
          .toList();
    } else {
      throw Exception('Failed to load popular movies');
    }
  }

  // Get popular TV shows
  Future<List<MediaItem>> getPopularTVShows() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tv/popular?api_key=$apiKey&language=en-US&page=1'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromTvJson(json, tvGenres))
          .toList();
    } else {
      throw Exception('Failed to load popular TV shows');
    }
  }

  // Get movie recommendations based on genres
  Future<List<MediaItem>> getMovieRecommendations(List<int> genreIds) async {
    final String genres = genreIds.join(',');
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genres&page=1',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromMovieJson(json, movieGenres))
          .toList();
    } else {
      throw Exception('Failed to load movie recommendations');
    }
  }

  // Get TV recommendations based on genres
  Future<List<MediaItem>> getTVRecommendations(List<int> genreIds) async {
    final String genres = genreIds.join(',');
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/tv?api_key=$apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genres&page=1',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromTvJson(json, tvGenres))
          .toList();
    } else {
      throw Exception('Failed to load TV recommendations');
    }
  }

  // Get cast for a movie or TV show
  Future<List<Map<String, dynamic>>> getCast(int id, bool isMovie) async {
    final String mediaType = isMovie ? 'movie' : 'tv';
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/credits?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final castList = data['cast'] as List;

      // Take only first 10 cast members
      return castList.take(10).map((actor) {
        return {
          'name': actor['name'] ?? '',
          'character': actor['character'] ?? '',
          'profileUrl': actor['profile_path'] != null
              ? 'https://image.tmdb.org/t/p/w200${actor['profile_path']}'
              : 'https://via.placeholder.com/200x300?text=No+Image',
        };
      }).toList();
    } else {
      throw Exception('Failed to load cast');
    }
  }

  // Get trailer URL for a movie or TV show
  Future<String?> getTrailerUrl(int id, bool isMovie) async {
    final String mediaType = isMovie ? 'movie' : 'tv';
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/videos?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;

      if (results.isNotEmpty) {
        final trailer = results.firstWhere(
              (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube',
          orElse: () => null,
        );

        if (trailer != null) {
          return 'https://youtu.be/${trailer['key']}';
        } else if (results.isNotEmpty) {
          return 'https://youtu.be/${results[0]['key']}';
        }
      }
    }

    return null; // No trailer found
  }
}
