import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart'; //

class TmdbService {
  // Replace with your TMDB API key
  final String apiKey = 'c77efa315e4a87ebcd95b283b83e7aad'; //
  final String baseUrl = 'https://api.themoviedb.org/3'; //

  // Genre maps
  final Map<int, String> movieGenres = { //
    28: 'Action', //
    12: 'Adventure', //
    16: 'Animation', //
    35: 'Comedy', //
    80: 'Crime', //
    99: 'Documentary', //
    18: 'Drama', //
    10751: 'Family', //
    14: 'Fantasy', //
    36: 'History', //
    27: 'Horror', //
    10402: 'Music', //
    9648: 'Mystery', //
    10749: 'Romance', //
    878: 'Science Fiction', //
    10770: 'TV Movie', //
    53: 'Thriller', //
    10752: 'War', //
    37: 'Western', //
  };

  final Map<int, String> tvGenres = { //
    10759: 'Action & Adventure', //
    16: 'Animation', //
    35: 'Comedy', //
    80: 'Crime', //
    99: 'Documentary', //
    18: 'Drama', //
    10751: 'Family', //
    10762: 'Kids', //
    9648: 'Mystery', //
    10763: 'News', //
    10764: 'Reality', //
    10765: 'Sci-Fi & Fantasy', //
    10766: 'Soap', //
    10767: 'Talk', //
    10768: 'War & Politics', //
    37: 'Western', //
  };

  // Get popular movies
  Future<List<MediaItem>> getPopularMovies() async { //
    final response = await http.get(
      Uri.parse('$baseUrl/trending/movie/day?api_key=$apiKey&language=en-US&page=1'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromMovieJson(json, movieGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load popular movies'); //
    }
  }

  // Get popular TV shows
  Future<List<MediaItem>> getPopularTVShows() async { //
    final response = await http.get(
      Uri.parse('$baseUrl/trending/tv/day?api_key=$apiKey'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromTvJson(json, tvGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load trending TV shows'); //
    }
  }

  // Get movie recommendations based on genres
  Future<List<MediaItem>> getMovieRecommendations(List<int> genreIds, {int page = 1}) async { //
    final String genres = genreIds.join(','); //
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genres&page=$page', //
      ),
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromMovieJson(json, movieGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load movie recommendations'); //
    }
  }

  // Get TV recommendations based on genres
  Future<List<MediaItem>> getTVRecommendations(List<int> genreIds, {int page = 1}) async { //
    final String genres = genreIds.join(','); //
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/tv?api_key=$apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genres&page=$page', //
      ),
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromTvJson(json, tvGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load TV recommendations'); //
    }
  }

  // Get cast for a movie or TV show
  Future<List<Map<String, dynamic>>> getCast(int id, bool isMovie) async { //
    final String mediaType = isMovie ? 'movie' : 'tv'; //
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/credits?api_key=$apiKey&language=en-US'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      final castList = data['cast'] as List; //

      // Take only first 10 cast members
      return castList.take(10).map((actor) { //
        return {
          'id': actor['id'] ?? 0,  // Add actor ID //
          'name': actor['name'] ?? '', //
          'character': actor['character'] ?? '', //
          'profileUrl': actor['profile_path'] != null //
              ? 'https://image.tmdb.org/t/p/w200${actor['profile_path']}' //
              : 'https://via.placeholder.com/200x300?text=No+Image', //
        };
      }).toList(); //
    } else {
      throw Exception('Failed to load cast'); //
    }
  }

  // Get trailer URL for a movie or TV show
  Future<String?> getTrailerUrl(int id, bool isMovie) async { //
    final String mediaType = isMovie ? 'movie' : 'tv'; //
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/videos?api_key=$apiKey'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      final results = data['results'] as List; //

      if (results.isNotEmpty) { //
        final trailer = results.firstWhere( //
              (v) => v['type'] == 'Trailer' && v['site'] == 'YouTube', //
          orElse: () => null, // Return null if not found, or the first result if needed //
        );

        if (trailer != null && trailer['key'] != null) { //
          return 'https://www.youtube.com/watch?v=${trailer['key']}'; // Corrected to standard YouTube URL
        } else {
          // Fallback to the first video if it's a YouTube video
          final firstYouTubeVideo = results.firstWhere( //
                (v) => v['site'] == 'YouTube' && v['key'] != null, //
            orElse: () => null, //
          );
          if (firstYouTubeVideo != null) { //
            return 'https://www.youtube.com/watch?v=${firstYouTubeVideo['key']}'; // Corrected to standard YouTube URL
          }
        }
      }
    }
    return null; // No suitable trailer found //
  }

  // Get similar movies
  Future<List<MediaItem>> getSimilarMovies(int movieId) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId/similar?api_key=$apiKey&language=en-US&page=1'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromMovieJson(json, movieGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load similar movies'); //
    }
  }

// Get similar TV shows
  Future<List<MediaItem>> getSimilarTVShows(int tvId) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/tv/$tvId/similar?api_key=$apiKey&language=en-US&page=1'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromTvJson(json, tvGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load similar TV shows'); //
    }
  }

  // Get movie details including runtime
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId?api_key=$apiKey&language=en-US'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      final int runtime = data['runtime'] ?? 0; //

      return { //
        'runtime': runtime, //
        'duration': _formatMovieDuration(runtime), //
      };
    } else {
      throw Exception('Failed to load movie details'); //
    }
  }

// Get TV show details including episode runtime
  Future<Map<String, dynamic>> getTVShowDetails(int tvId) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/tv/$tvId?api_key=$apiKey&language=en-US'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      final List<dynamic> episodeRuntime = data['episode_run_time'] ?? []; //
      final int numberOfEpisodes = data['number_of_episodes'] ?? 0; //

      int avgRuntime = 0; //
      if (episodeRuntime.isNotEmpty) { //
        // Ensure all elements are numbers before reducing
        final List<int> runtimes = episodeRuntime.whereType<int>().toList(); //
        if (runtimes.isNotEmpty) { //
          avgRuntime = runtimes.reduce((a, b) => a + b) ~/ runtimes.length; //
        }
      }

      return { //
        'episodeRuntime': avgRuntime, //
        'numberOfEpisodes': numberOfEpisodes, //
        'duration': _formatTVDuration(avgRuntime, numberOfEpisodes), //
      };
    } else {
      throw Exception('Failed to load TV show details'); //
    }
  }

// Helper method to format movie duration
  String _formatMovieDuration(int minutes) { //
    if (minutes <= 0) return 'Unknown duration'; //

    final hours = minutes ~/ 60; //
    final remainingMinutes = minutes % 60; //

    if (hours > 0) { //
      return '${hours}h ${remainingMinutes}m'; //
    } else {
      return '${remainingMinutes}m'; //
    }
  }

// Helper method to format TV duration
  String _formatTVDuration(int minutes, int episodes) { //
    if (minutes <= 0) return episodes > 0 ? '$episodes episodes' : 'Unknown duration'; //

    return '${minutes}m per episode | $episodes episodes'; //
  }

  // Get actor details including biography
  Future<Map<String, dynamic>> getActorDetails(int actorId) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/person/$actorId?api_key=$apiKey&language=en-US'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return { //
        'name': data['name'] ?? '', //
        'biography': data['biography'] ?? '', //
        'birthday': data['birthday'] ?? '', //
        'deathday': data['deathday'] ?? '', // Can be null if actor is alive //
        'placeOfBirth': data['place_of_birth'] ?? '', //
        'profileUrl': data['profile_path'] != null //
            ? 'https://image.tmdb.org/t/p/w500${data['profile_path']}' //
            : 'https://via.placeholder.com/500x750?text=No+Image', //
      };
    } else {
      throw Exception('Failed to load actor details'); //
    }
  }

// Get actor filmography with sorting options
  Future<List<MediaItem>> getActorFilmography(int actorId, String sortBy) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/person/$actorId/combined_credits?api_key=$apiKey&language=en-US'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      final List<dynamic> cast = data['cast'] as List; //
      final List<dynamic> sortedCast = List.from(cast); //

      // Apply sorting
      switch (sortBy) { //
        case 'vote_average': //
          sortedCast.sort((a, b) => //
          ((b['vote_average'] ?? 0.0) as num).compareTo((a['vote_average'] ?? 0.0) as num)); //
          break;
        case 'release_date': //
          sortedCast.sort((a, b) { //
            final String dateA = a['media_type'] == 'movie' //
                ? (a['release_date'] ?? '0000-00-00') // Fallback for missing dates //
                : (a['first_air_date'] ?? '0000-00-00'); //
            final String dateB = b['media_type'] == 'movie' //
                ? (b['release_date'] ?? '0000-00-00') //
                : (b['first_air_date'] ?? '0000-00-00'); //
            return dateB.compareTo(dateA); // Sort by newest first //
          });
          break;
        case 'popularity': //
        default: //
          sortedCast.sort((a, b) => //
          ((b['popularity'] ?? 0.0) as num).compareTo((a['popularity'] ?? 0.0) as num)); //
          break;
      }

      // Filter out items with empty titles or invalid IDs
      final List<dynamic> filteredCast = sortedCast.where((item) { //
        final bool isMovie = item['media_type'] == 'movie'; //
        final String title = isMovie ? (item['title'] ?? '') : (item['name'] ?? ''); //
        final int id = item['id'] ?? 0; //
        return title.isNotEmpty && id != 0; //
      }).toList(); //

      return filteredCast.map((item) { //
        if (item['media_type'] == 'movie') { //
          return MediaItem.fromMovieJson(item, movieGenres, character: item['character']); //
        } else if (item['media_type'] == 'tv') { //
          return MediaItem.fromTvJson(item, tvGenres, character: item['character']); //
        }
        // Should not happen if filtered correctly, but as a fallback:
        return MediaItem( //
            id: item['id'] ?? 0, //
            title: 'Unknown Media', //
            overview: '', //
            posterUrl: 'https://via.placeholder.com/500x750?text=No+Image', //
            backdropUrl: 'https://via.placeholder.com/1280x720?text=No+Image', //
            rating: 0.0, //
            year: '', //
            genres: [], //
            isMovie: true, // Default //
            character: item['character'] ?? '' //
        );
      }).whereType<MediaItem>().toList(); // Ensure only MediaItems are returned //
    } else {
      throw Exception('Failed to load actor filmography'); //
    }
  }

// NEW METHODS FOR SEARCH FUNCTIONALITY

  // Search for movies
  Future<List<MediaItem>> searchMovies(String query) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/search/movie?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromMovieJson(json, movieGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to search movies'); //
    }
  }

  // Search for TV shows
  Future<List<MediaItem>> searchTVShows(String query) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/search/tv?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromTvJson(json, tvGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to search TV shows'); //
    }
  }

  // Search for actors
  Future<List<Map<String, dynamic>>> searchActors(String query) async { //
    final response = await http.get(
      Uri.parse('$baseUrl/search/person?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'), //
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .where((json) => json['known_for_department'] == 'Acting') //
          .map((json) { //
        return {
          'id': json['id'] ?? 0, //
          'name': json['name'] ?? '', //
          'popularity': json['popularity'] ?? 0.0, //
          'profileUrl': json['profile_path'] != null //
              ? 'https://image.tmdb.org/t/p/w200${json['profile_path']}' //
              : 'https://via.placeholder.com/200x300?text=No+Image', //
        };
      })
          .toList(); //
    } else {
      throw Exception('Failed to search actors'); //
    }
  }

  // Get Top Rated / All-Time Popular Movies
  Future<List<MediaItem>> getTopRatedMovies({int page = 1}) async { //
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/movie?api_key=$apiKey&language=en-US&sort_by=vote_average.desc&vote_count.gte=1000&page=$page&include_adult=false', //
      ),
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromMovieJson(json, movieGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load top-rated movies'); //
    }
  }

  // Get Top Rated / All-Time Popular TV Shows
  Future<List<MediaItem>> getTopRatedTVShows({int page = 1}) async { //
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/tv?api_key=$apiKey&language=en-US&sort_by=vote_average.desc&vote_count.gte=500&page=$page&include_adult=false', //
      ),
    );

    if (response.statusCode == 200) { //
      final data = json.decode(response.body); //
      return (data['results'] as List) //
          .map((json) => MediaItem.fromTvJson(json, tvGenres)) //
          .toList(); //
    } else {
      throw Exception('Failed to load top-rated TV shows'); //
    }
  }
}