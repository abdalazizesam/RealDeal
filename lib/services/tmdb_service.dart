import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';
import 'dart:math';
import 'dart:async';

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
      Uri.parse('$baseUrl/trending/movie/day?api_key=$apiKey&language=en-US&page=1'),
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
      Uri.parse('$baseUrl/trending/tv/day?api_key=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromTvJson(json, tvGenres))
          .toList();
    } else {
      throw Exception('Failed to load trending TV shows');
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
          'id': actor['id'] ?? 0,  // Add actor ID
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

  // Get similar movies
  Future<List<MediaItem>> getSimilarMovies(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId/similar?api_key=$apiKey&language=en-US&page=1'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromMovieJson(json, movieGenres))
          .toList();
    } else {
      throw Exception('Failed to load similar movies');
    }
  }

// Get similar TV shows
  Future<List<MediaItem>> getSimilarTVShows(int tvId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tv/$tvId/similar?api_key=$apiKey&language=en-US&page=1'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromTvJson(json, tvGenres))
          .toList();
    } else {
      throw Exception('Failed to load similar TV shows');
    }
  }

  // Get movie details including runtime
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final int runtime = data['runtime'] ?? 0;

      return {
        'runtime': runtime,
        'duration': _formatMovieDuration(runtime),
      };
    } else {
      throw Exception('Failed to load movie details');
    }
  }

// Get TV show details including episode runtime
  Future<Map<String, dynamic>> getTVShowDetails(int tvId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tv/$tvId?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> episodeRuntime = data['episode_run_time'] ?? [];
      final int numberOfEpisodes = data['number_of_episodes'] ?? 0;

      int avgRuntime = 0;
      if (episodeRuntime.isNotEmpty) {
        avgRuntime = episodeRuntime.reduce((a, b) => a + b) ~/ episodeRuntime.length;
      }

      return {
        'episodeRuntime': avgRuntime,
        'numberOfEpisodes': numberOfEpisodes,
        'duration': _formatTVDuration(avgRuntime, numberOfEpisodes),
      };
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

// Helper method to format movie duration
  String _formatMovieDuration(int minutes) {
    if (minutes <= 0) return 'Unknown duration';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

// Helper method to format TV duration
  String _formatTVDuration(int minutes, int episodes) {
    if (minutes <= 0) return episodes > 0 ? '$episodes episodes' : 'Unknown duration';

    return '${minutes}m per episode | $episodes episodes';
  }

  // Get actor details including biography
  Future<Map<String, dynamic>> getActorDetails(int actorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$actorId?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'name': data['name'] ?? '',
        'biography': data['biography'] ?? '',
        'birthday': data['birthday'] ?? '',
        'deathday': data['deathday'] ?? '',
        'placeOfBirth': data['place_of_birth'] ?? '',
        'profileUrl': data['profile_path'] != null
            ? 'https://image.tmdb.org/t/p/w500${data['profile_path']}'
            : 'https://via.placeholder.com/500x750?text=No+Image',
      };
    } else {
      throw Exception('Failed to load actor details');
    }
  }

// Get actor filmography with sorting options
  Future<List<MediaItem>> getActorFilmography(int actorId, String sortBy) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$actorId/combined_credits?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> cast = data['cast'] as List;
      final List<dynamic> sortedCast = List.from(cast);

      // Apply sorting
      switch (sortBy) {
        case 'vote_average':
          sortedCast.sort((a, b) =>
              ((b['vote_average'] ?? 0) as num).compareTo((a['vote_average'] ?? 0) as num));
          break;
        case 'release_date':
          sortedCast.sort((a, b) {
            final String dateA = a['media_type'] == 'movie'
                ? (a['release_date'] ?? '')
                : (a['first_air_date'] ?? '');
            final String dateB = b['media_type'] == 'movie'
                ? (b['release_date'] ?? '')
                : (b['first_air_date'] ?? '');
            return dateB.compareTo(dateA); // Sort by newest first
          });
          break;
        case 'popularity':
        default:
          sortedCast.sort((a, b) =>
              ((b['popularity'] ?? 0) as num).compareTo((a['popularity'] ?? 0) as num));
          break;
      }

      // Filter out items with empty titles
      final List<dynamic> filteredCast = sortedCast.where((item) {
        final bool isMovie = item['media_type'] == 'movie';
        final String title = isMovie ? (item['title'] ?? '') : (item['name'] ?? '');
        return title.isNotEmpty;
      }).toList();

      return filteredCast.map((item) {
        final bool isMovie = item['media_type'] == 'movie';
        final String title = isMovie ? (item['title'] ?? '') : (item['name'] ?? '');
        final String releaseDate = isMovie
            ? (item['release_date'] ?? '')
            : (item['first_air_date'] ?? '');
        final String year = releaseDate.isNotEmpty ? releaseDate.substring(0, min(4, releaseDate.length)) : '';

        // Extract genre names from ids
        final List<int> genreIds = List<int>.from(item['genre_ids'] ?? []);
        final List<String> genreNames = genreIds.map((id) {
          return isMovie ? (movieGenres[id] ?? '') : (tvGenres[id] ?? '');
        }).where((name) => name.isNotEmpty).toList();

        return MediaItem(
          id: item['id'] ?? 0,
          title: title,
          overview: item['overview'] ?? 'No description available',
          posterUrl: item['poster_path'] != null
              ? 'https://image.tmdb.org/t/p/w500${item['poster_path']}'
              : 'https://via.placeholder.com/500x750?text=No+Image',
          backdropUrl: item['backdrop_path'] != null
              ? 'https://image.tmdb.org/t/p/w1280${item['backdrop_path']}'
              : 'https://via.placeholder.com/1280x720?text=No+Image',
          rating: (item['vote_average'] ?? 0).toDouble(),
          year: year,
          genres: genreNames,
          isMovie: isMovie,
          character: item['character'] ?? '',
        );
      }).toList();
    } else {
      throw Exception('Failed to load actor filmography');
    }
  }

// NEW METHODS FOR SEARCH FUNCTIONALITY

  // Search for movies
  Future<List<MediaItem>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/movie?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromMovieJson(json, movieGenres))
          .toList();
    } else {
      throw Exception('Failed to search movies');
    }
  }

  // Search for TV shows
  Future<List<MediaItem>> searchTVShows(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/tv?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((json) => MediaItem.fromTvJson(json, tvGenres))
          .toList();
    } else {
      throw Exception('Failed to search TV shows');
    }
  }

  // Search for actors
  Future<List<Map<String, dynamic>>> searchActors(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/person?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .where((json) => json['known_for_department'] == 'Acting')
          .map((json) {
        return {
          'id': json['id'] ?? 0,
          'name': json['name'] ?? '',
          'popularity': json['popularity'] ?? 0.0,
          'profileUrl': json['profile_path'] != null
              ? 'https://image.tmdb.org/t/p/w200${json['profile_path']}'
              : 'https://via.placeholder.com/200x300?text=No+Image',
        };
      })
          .toList();
    } else {
      throw Exception('Failed to search actors');
    }
  }
}


