// Service xử lý API liên quan đến phim (Danh sách, Chi tiết, Tìm kiếm).
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_model.dart';
import '../models/movie_detail_model.dart';
import 'api_config.dart';

class MovieService {
  Future<List<Movie>> getMoviesLimit(int limit) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getMoviesLimitUrl(limit)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies: $e');
      return [];
    }
  }

  Future<List<Movie>> getMoviesByCategory(
    String slug, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMoviesByCategoryUrl(slug)).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies by category: $e');
      return [];
    }
  }

  Future<List<Movie>> getMoviesByYear(
    int year, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMoviesByYearUrl(year)).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies by year: $e');
      return [];
    }
  }

  /// Lọc phim đa tiêu chí (thể loại, quốc gia, năm, khoảng năm, sub, sắp xếp).
  Future<List<Movie>> getFilteredMovies({
    String category = '',
    String country = '',
    String type = '',
    int year = 0,
    int yearFrom = 0,
    int yearTo = 0,
    String lang = '',
    String sort = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final qp = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category.isNotEmpty) qp['category'] = category;
      if (country.isNotEmpty) qp['country'] = country;
      if (type.isNotEmpty) qp['type'] = type;
      if (year > 0) qp['year'] = year.toString();
      if (yearFrom > 0) qp['yearFrom'] = yearFrom.toString();
      if (yearTo > 0) qp['yearTo'] = yearTo.toString();
      if (lang.isNotEmpty) qp['lang'] = lang;
      if (sort.isNotEmpty) qp['sort'] = sort;

      final uri =
          Uri.parse(ApiConfig.filterMoviesUrl).replace(queryParameters: qp);
      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching filtered movies: $e');
      return [];
    }
  }

  /// Phim hot: xếp hạng theo điểm khán giả TMDB (backend tính sẵn).
  Future<List<Movie>> getHotMovies({int limit = 12}) async {
    try {
      final uri = Uri.parse(ApiConfig.hotMoviesUrl)
          .replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching hot movies: $e');
      return [];
    }
  }

  Future<List<Movie>> getMoviesByCountry(
    String slug, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMoviesByCountryUrl(slug)).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies by country: $e');
      return [];
    }
  }

  Future<List<Movie>> getMoviesByType(
    String type, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getMoviesByTypeUrl(type)).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movies by type: $e');
      return [];
    }
  }

  Future<Map<String, List<Movie>>?> getHomeData() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.homeDataUrl))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is Map) {
          final Map<String, dynamic> sections = data['data'];
          final result = <String, List<Movie>>{};
          for (final entry in sections.entries) {
            if (entry.value is List) {
              result[entry.key] = (entry.value as List)
                  .map((json) => Movie.fromJson(json))
                  .toList();
            }
          }
          return result;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching home data: $e');
      return null;
    }
  }

  Future<Movie?> getMovieDetail(String slug) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getMovieDetailUrl(slug)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Movie.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching movie detail: $e');
      return null;
    }
  }

  Future<MovieDetail?> getMovieDetailFull(String slug) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getMovieDetailUrl(slug)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == true || data['success'] == true) {
          final movieJson = data['movie'] ?? data['data'];
          return MovieDetail.fromJson(movieJson);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching full movie detail: $e');
      return null;
    }
  }

  /// Diễn viên kèm ảnh thật (TMDB qua backend). Trả [] nếu không có dữ liệu.
  Future<List<Map<String, dynamic>>> getMovieCast(String slug) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.getMovieCastUrl(slug)))
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching movie cast: $e');
      return [];
    }
  }

  Future<List<Movie>> searchMovies(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.searchMoviesUrl).replace(
        queryParameters: {
          'search': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> moviesData = data['data'];
          return moviesData.map((json) => Movie.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }
}
