import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class TmdbService {
  final String apiKey = 'c77efa315e4a87ebcd95b283b83e7aad';
  final String baseUrl = 'https://api.themoviedb.org/3';

  final Map<int, String> movieGenres = {
    28: 'Action', 12: 'Adventure', 16: 'Animation', 35: 'Comedy', 80: 'Crime',
    99: 'Documentary', 18: 'Drama', 10751: 'Family', 14: 'Fantasy', 36: 'History',
    27: 'Horror', 10402: 'Music', 9648: 'Mystery', 10749: 'Romance',
    878: 'Science Fiction', 10770: 'TV Movie', 53: 'Thriller', 10752: 'War',
    37: 'Western',
  };

  final Map<int, String> tvGenres = {
    10759: 'Action & Adventure', 16: 'Animation', 35: 'Comedy', 80: 'Crime',
    99: 'Documentary', 18: 'Drama', 10751: 'Family', 10762: 'Kids',
    9648: 'Mystery', 10763: 'News', 10764: 'Reality', 10765: 'Sci-Fi & Fantasy',
    10766: 'Soap', 10767: 'Talk', 10768: 'War & Politics', 37: 'Western',
  };

  // New: In-memory cache for TV show details
  final Map<int, Map<String, dynamic>> _tvDetailsCache = {};

  // New: Public method to clear TV details cache for a specific ID
  void invalidateTvDetailsCache(int tvId) {
    _tvDetailsCache.remove(tvId);
  }

  Future<List<MediaItem>> getPopularMovies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/trending/movie/day?api_key=$apiKey&language=en-US&page=1'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromMovieJson(json, movieGenres)).toList();
    } else { throw Exception('Failed to load popular movies'); }
  }

  Future<List<MediaItem>> getPopularTVShows() async {
    final response = await http.get(
      Uri.parse('$baseUrl/trending/tv/day?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromTvJson(json, tvGenres)).toList();
    } else { throw Exception('Failed to load trending TV shows'); }
  }

  Future<List<MediaItem>> getMovieRecommendations(List<int> genreIds, {int page = 1}) async {
    final String genres = genreIds.join(',');
    final response = await http.get(
      Uri.parse('$baseUrl/discover/movie?api_key=$apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genres&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromMovieJson(json, movieGenres)).toList();
    } else { throw Exception('Failed to load movie recommendations'); }
  }

  Future<List<MediaItem>> getTVRecommendations(List<int> genreIds, {int page = 1}) async {
    final String genres = genreIds.join(',');
    final response = await http.get(
      Uri.parse('$baseUrl/discover/tv?api_key=$apiKey&language=en-US&sort_by=popularity.desc&with_genres=$genres&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromTvJson(json, tvGenres)).toList();
    } else { throw Exception('Failed to load TV recommendations'); }
  }

  Future<List<Map<String, dynamic>>> getCast(int id, bool isMovie) async {
    final String mediaType = isMovie ? 'movie' : 'tv';
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/credits?api_key=$apiKey&language=en-US'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final castList = data['cast'] as List;
      return castList.take(10).map((actor) {
        return {
          'id': actor['id'] ?? 0, 'name': actor['name'] ?? '',
          'character': actor['character'] ?? '',
          'profileUrl': actor['profile_path'] != null ? 'https://image.tmdb.org/t/p/w200${actor['profile_path']}' : 'https://via.placeholder.com/200x300?text=No+Image',
        };
      }).toList();
    } else { throw Exception('Failed to load cast'); }
  }

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
        if (trailer != null && trailer['key'] != null) {
          return 'https://www.youtube.com/watch?v=${trailer['key']}';
        } else {
          final firstYouTubeVideo = results.firstWhere(
                (v) => v['site'] == 'YouTube' && v['key'] != null,
            orElse: () => null,
          );
          if (firstYouTubeVideo != null) {
            return 'https://www.youtube.com/watch?v=${firstYouTubeVideo['key']}';
          }
        }
      }
    }
    return null;
  }

  Future<List<MediaItem>> getSimilarMovies(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId/similar?api_key=$apiKey&language=en-US&page=1'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromMovieJson(json, movieGenres)).toList();
    } else { throw Exception('Failed to load similar movies'); }
  }

  Future<List<MediaItem>> getSimilarTVShows(int tvId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tv/$tvId/similar?api_key=$apiKey&language=en-US&page=1'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromTvJson(json, tvGenres)).toList();
    } else { throw Exception('Failed to load similar TV shows'); }
  }

  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/$movieId?api_key=$apiKey&language=en-US'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final int runtime = data['runtime'] ?? 0;
      final String originalLanguage = data['original_language'] ?? '';
      final String originalTitle = data['original_title'] ?? ''; // New
      final String status = data['status'] ?? ''; // New
      final int budget = data['budget'] ?? 0;
      final int revenue = data['revenue'] ?? 0;

      return {
        'runtime': runtime,
        'duration': _formatMovieDuration(runtime),
        'original_language': originalLanguage,
        'original_title': originalTitle, // New
        'status': status, // New
        'budget': budget,
        'revenue': revenue,
      };
    } else {
      throw Exception('Failed to load movie details');
    }
  }


  // New method: Get upcoming movies
  Future<List<MediaItem>> getUpcomingMovies({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/movie/upcoming?api_key=$apiKey&language=en-US&page=$page'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromMovieJson(json, movieGenres)).toList();
    } else {
      throw Exception('Failed to load upcoming movies');
    }
  }

  // New method: Get TV shows currently airing (today)
  Future<List<MediaItem>> getTopAiringTVShows({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tv/on_the_air?api_key=$apiKey&language=en-US&page=$page'), // 'on_the_air' for currently airing, 'airing_today' for today only
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromTvJson(json, tvGenres)).toList();
    } else {
      throw Exception('Failed to load top airing TV shows');
    }
  }

  // Modify existing getTopRatedMovies to optionally sort by popularity
  Future<List<MediaItem>> getTopRatedMovies({int page = 1, bool sortByPopularity = false}) async {
    String sortBy = sortByPopularity ? 'popularity.desc' : 'vote_average.desc';
    final response = await http.get(
      Uri.parse('$baseUrl/discover/movie?api_key=$apiKey&language=en-US&sort_by=$sortBy&vote_count.gte=1000&page=$page&include_adult=false'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromMovieJson(json, movieGenres)).toList();
    } else {
      throw Exception('Failed to load top-rated movies');
    }
  }

  // Modify existing getTopRatedTVShows to optionally sort by popularity
  Future<List<MediaItem>> getTopRatedTVShows({int page = 1, bool sortByPopularity = false}) async {
    String sortBy = sortByPopularity ? 'popularity.desc' : 'vote_average.desc';
    final response = await http.get(
      Uri.parse('$baseUrl/discover/tv?api_key=$apiKey&language=en-US&sort_by=$sortBy&vote_count.gte=500&page=$page&include_adult=false'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromTvJson(json, tvGenres)).toList();
    } else {
      throw Exception('Failed to load top-rated TV shows');
    }
  }

  // Modified: Use cache for TV show details
  Future<Map<String, dynamic>> getTVShowDetails(int tvId) async {
    // Check cache first
    if (_tvDetailsCache.containsKey(tvId)) {
      return _tvDetailsCache[tvId]!;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/tv/$tvId?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> episodeRuntime = data['episode_run_time'] ?? [];
      final String originalLanguage = data['original_language'] ?? '';
      final int numberOfEpisodes = data['number_of_episodes'] ?? 0;
      final String status = data['status'] ?? ''; // New

      int avgRuntime = 0;
      final List<int> runtimes = episodeRuntime.whereType<int>().toList();
      if (runtimes.isNotEmpty) {
        avgRuntime = runtimes.reduce((a, b) => a + b) ~/ runtimes.length;
      }

      final Map<String, dynamic> details = {
        'episodeRuntime': avgRuntime,
        'numberOfEpisodes': numberOfEpisodes,
        'duration': _formatTVDuration(avgRuntime, numberOfEpisodes),
        'original_language': originalLanguage,
        'status': status, // New
      };

      // Cache the result
      _tvDetailsCache[tvId] = details;
      return details;
    } else {
      throw Exception('Failed to load TV show details');
    }
  }

  // New Function: Get just the total number of episodes for a TV show
  Future<int?> getTvShowTotalEpisodes(int tvId) async {
    try {
      final details = await getTVShowDetails(tvId); // This method now handles caching
      return details['numberOfEpisodes'] as int?;
    } catch (e) {
      print('Error getting total episodes for TV show $tvId: $e');
      return null;
    }
  }

  String _formatMovieDuration(int minutes) {
    if (minutes <= 0) return 'Unknown duration';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) { return '${hours}h ${remainingMinutes}m'; } else { return '${remainingMinutes}m'; }
  }

  String _formatTVDuration(int minutes, int episodes) {
    if (minutes <= 0) return episodes > 0 ? '$episodes episodes' : 'Unknown duration';
    return '${minutes}m per episode | $episodes episodes';
  }

  Future<Map<String, dynamic>> getActorDetails(int actorId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$actorId?api_key=$apiKey&language=en-US'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'name': data['name'] ?? '', 'biography': data['biography'] ?? '',
        'birthday': data['birthday'] ?? '', 'deathday': data['deathday'] ?? '',
        'placeOfBirth': data['place_of_birth'] ?? '',
        'profileUrl': data['profile_path'] != null ? 'https://image.tmdb.org/t/p/w500${data['profile_path']}' : 'https://via.placeholder.com/500x750?text=No+Image',
      };
    } else { throw Exception('Failed to load actor details'); }
  }

  Future<List<MediaItem>> getActorFilmography(int actorId, String sortBy) async {
    final response = await http.get(
      Uri.parse('$baseUrl/person/$actorId/combined_credits?api_key=$apiKey&language=en-US'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> castAndCrewCredits = data['cast'] as List;
      final List<dynamic> sortedCredits = List.from(castAndCrewCredits);

      switch (sortBy) {
        case 'vote_average':
          sortedCredits.sort((a, b) =>
              ((b['vote_average'] ?? 0.0) as num).compareTo((a['vote_average'] ?? 0.0) as num));
          break;
        case 'release_date':
          sortedCredits.sort((a, b) {
            final String dateA = a['media_type'] == 'movie' ? (a['release_date'] ?? '9999-99-99') : (a['first_air_date'] ?? '9999-99-99');
            final String dateB = b['media_type'] == 'movie' ? (b['release_date'] ?? '9999-99-99') : (b['first_air_date'] ?? '9999-99-99');
            if (dateA == '0000-00-00' || dateA.isEmpty) return 1;
            if (dateB == '0000-00-00' || dateB.isEmpty) return -1;
            return dateB.compareTo(dateA);
          });
          break;
        case 'popularity':
        default:
          sortedCredits.sort((a, b) =>
              ((b['popularity'] ?? 0.0) as num).compareTo((a['popularity'] ?? 0.0) as num));
          break;
      }

      final List<dynamic> initiallyFilteredCredits = sortedCredits.where((item) {
        final bool isMovie = item['media_type'] == 'movie';
        final String title = isMovie ? (item['title'] ?? '') : (item['name'] ?? '');
        final int id = item['id'] ?? 0;
        final String characterName = (item['character'] ?? '').toString().toLowerCase();
        final List<int> genreIds = List<int>.from(item['genre_ids'] ?? []);

        bool isTalkShow = false;
        if (!isMovie && genreIds.contains(10767)) {
          isTalkShow = true;
        }

        return (item['media_type'] == 'movie' || item['media_type'] == 'tv') &&
            title.isNotEmpty &&
            id != 0 &&
            item['poster_path'] != null &&
            characterName != 'self' &&
            !isTalkShow;
      }).toList();

      final List<dynamic> deduplicatedCredits = [];
      final Set<int> processedTvShowIds = <int>{};

      for (var item in initiallyFilteredCredits) {
        if (item['media_type'] == 'tv') {
          final int tvShowId = item['id'] ?? 0;
          if (tvShowId != 0 && !processedTvShowIds.contains(tvShowId)) {
            deduplicatedCredits.add(item);
            processedTvShowIds.add(tvShowId);
          }
        } else {
          deduplicatedCredits.add(item);
        }
      }

      return deduplicatedCredits.map((item) {
        if (item['media_type'] == 'movie') {
          return MediaItem.fromMovieJson(item, movieGenres, character: item['character']);
        } else if (item['media_type'] == 'tv') {
          return MediaItem.fromTvJson(item, tvGenres, character: item['character']);
        }
        return MediaItem(id: item['id'] ?? 0, title: 'Unknown Media', overview: '', posterUrl: 'https://via.placeholder.com/500x750?text=No+Image', backdropUrl: 'https://via.placeholder.com/1280x720?text=No+Image', rating: 0.0, year: '', genres: [], isMovie: true, character: item['character'] ?? '');
      }).whereType<MediaItem>().toList();
    } else { throw Exception('Failed to load actor filmography'); }
  }

  Future<List<MediaItem>> getActorKnownFor(int actorId, {int limit = 8}) async {
    try {
      final List<MediaItem> popularWorks = await getActorFilmography(actorId, 'popularity');
      return popularWorks.take(limit).toList();
    } catch (e) { throw Exception('Failed to load "Known For" for actor: $e'); }
  }

  Future<Map<String, dynamic>> getWatchProviders(int id, bool isMovie) async {
    final String mediaType = isMovie ? 'movie' : 'tv';
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/watch/providers?api_key=$apiKey'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as Map<String, dynamic>?;
      final usProviders = results?['US'] as Map<String, dynamic>?;
      if (usProviders != null) { return usProviders; } else if (results != null && results.isNotEmpty) { return results.values.first as Map<String, dynamic>; }
      return {};
    } else { throw Exception('Failed to load watch providers'); }
  }

  Future<Map<String, List<String>>> getCrewDetails(int id, bool isMovie) async {
    final String mediaType = isMovie ? 'movie' : 'tv';
    final response = await http.get(
      Uri.parse('$baseUrl/$mediaType/$id/credits?api_key=$apiKey&language=en-US'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> crewList = data['crew'] as List;
      String director = '';
      final List<String> writers = [];
      final List<String> creators = [];
      for (var person in crewList) {
        final String job = person['job'] ?? '';
        final String name = person['name'] ?? '';
        if (job == 'Director' && director.isEmpty) { director = name; }
        if (job == 'Writer' || job == 'Screenplay' || job == 'Story') { writers.add(name); }
        if (isMovie == false && job == 'Creator') { creators.add(name); }
      }
      return { 'director': [director], 'writers': writers.toSet().toList(), 'creators': creators.toSet().toList(), };
    } else { throw Exception('Failed to load crew details'); }
  }

  Future<List<MediaItem>> searchMovies(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/movie?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromMovieJson(json, movieGenres)).toList();
    } else { throw Exception('Failed to search movies'); }
  }

  Future<List<MediaItem>> searchTVShows(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/tv?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).map((json) => MediaItem.fromTvJson(json, tvGenres)).toList();
    } else { throw Exception('Failed to search TV shows'); }
  }

  Future<List<Map<String, dynamic>>> searchActors(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search/person?api_key=$apiKey&language=en-US&query=${Uri.encodeComponent(query)}&page=1&include_adult=false'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List).where((json) => json['known_for_department'] == 'Acting').map((json) {
        return {
          'id': json['id'] ?? 0, 'name': json['name'] ?? '',
          'popularity': json['popularity'] ?? 0.0,
          'profileUrl': json['profile_path'] != null ? 'https://image.tmdb.org/t/p/w200${json['profile_path']}' : 'https://via.placeholder.com/200x300?text=No+Image',
        };
      }).toList();
    } else { throw Exception('Failed to search actors'); }
  }
}