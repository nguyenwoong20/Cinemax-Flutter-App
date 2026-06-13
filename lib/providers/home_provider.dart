import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_notifier.dart';

enum SaveMovieAction { saved, removed, failed }

class HomeProvider extends ChangeNotifier {
  HomeProvider({AuthService? authService, MovieService? movieService})
    : _authService = authService ?? AuthService(),
      _movieService = movieService ?? MovieService() {
    savedMovieNotifier.addListener(_onSavedMoviesChanged);
  }

  final AuthService _authService;
  final MovieService _movieService;

  User? _user;
  List<Movie> _featuredMovies = [];
  List<Movie> _newMovies = [];
  List<Movie> _recommendedMovies = [];
  List<Movie> _koreanDramas = [];
  List<Movie> _chineseDramas = [];
  List<Movie> _vietnamMovies = [];
  List<Movie> _animationMovies = [];
  List<Movie> _singleMovies = [];
  List<Movie> _seriesMovies = [];
  List<Movie> _continueWatching = [];
  bool _isLoading = true;

  User? get user => _user;
  List<Movie> get featuredMovies => _featuredMovies;
  List<Movie> get newMovies => _newMovies;
  List<Movie> get recommendedMovies => _recommendedMovies;
  List<Movie> get koreanDramas => _koreanDramas;
  List<Movie> get chineseDramas => _chineseDramas;
  List<Movie> get vietnamMovies => _vietnamMovies;
  List<Movie> get animationMovies => _animationMovies;
  List<Movie> get singleMovies => _singleMovies;
  List<Movie> get seriesMovies => _seriesMovies;
  List<Movie> get continueWatching => _continueWatching;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.getUser();

    // 1 request duy nhất lấy toàn bộ dữ liệu trang chủ (thay vì 10 request song song
    // gây nghẽn Lambda cold-start → section lúc có lúc không)
    final home = await _movieService.getHomeData();

    await savedMovieNotifier.loadSavedMovies();

    _user = user;

    if (home != null) {
      final hot = home['hot'] ?? [];
      final latest = home['latest'] ?? [];
      _featuredMovies = hot.isNotEmpty ? hot : latest;
      _newMovies = latest;
      _koreanDramas = home['korean'] ?? [];
      _chineseDramas = home['chinese'] ?? [];
      _vietnamMovies = home['vietnam'] ?? [];
      _animationMovies = home['animation'] ?? [];
      _singleMovies = home['single'] ?? [];
      _seriesMovies = home['series'] ?? [];
    } else {
      // Fallback: gọi riêng lẻ nếu endpoint /home lỗi
      final results = await Future.wait([
        _movieService.getHotMovies(limit: 12),
        _movieService.getMoviesLimit(12),
        _movieService.getMoviesByCountry('han-quoc', limit: 12),
        _movieService.getMoviesByCountry('trung-quoc', limit: 12),
        _movieService.getMoviesByCountry('viet-nam', limit: 12),
        _movieService.getMoviesByType('hoathinh', limit: 12),
        _movieService.getMoviesByType('single', limit: 12),
        _movieService.getMoviesByType('series', limit: 12),
      ]);
      _featuredMovies = results[0].isNotEmpty ? results[0] : results[1];
      _newMovies = results[1];
      _koreanDramas = results[2];
      _chineseDramas = results[3];
      _vietnamMovies = results[4];
      _animationMovies = results[5];
      _singleMovies = results[6];
      _seriesMovies = results[7];
    }

    _continueWatching = await _loadContinueWatching();
    _isLoading = false;
    notifyListeners();
  }

  /// Phim xem dở gần đây: lấy slug từ lịch sử local rồi tra thông tin phim.
  Future<List<Movie>> _loadContinueWatching() async {
    final progresses = await HistoryService().getAllProgress();
    final recent = progresses.take(10).toList();
    if (recent.isEmpty) return [];

    final movies = await Future.wait(
      recent.map((p) => _movieService.getMovieDetail(p.movieSlug)),
    );
    return movies.whereType<Movie>().toList();
  }

  Future<void> removeFromContinueWatching(String slug) async {
    await HistoryService().clearProgress(slug);
    _continueWatching.removeWhere((m) => m.slug == slug);
    notifyListeners();
  }

  bool isMovieSaved(String slug) {
    return savedMovieNotifier.isMovieSaved(slug);
  }

  Future<SaveMovieAction> toggleFeaturedMovieSave(int index) async {
    if (index >= _featuredMovies.length) {
      return SaveMovieAction.failed;
    }

    final movie = _featuredMovies[index];
    final isCurrentlySaved = savedMovieNotifier.isMovieSaved(movie.slug);

    if (isCurrentlySaved) {
      final success = await savedMovieNotifier.removeSavedMovie(movie.slug);
      return success ? SaveMovieAction.removed : SaveMovieAction.failed;
    }

    final success = await savedMovieNotifier.saveMovie(movie.slug);
    return success ? SaveMovieAction.saved : SaveMovieAction.failed;
  }

  void _onSavedMoviesChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    savedMovieNotifier.removeListener(_onSavedMoviesChanged);
    super.dispose();
  }
}
