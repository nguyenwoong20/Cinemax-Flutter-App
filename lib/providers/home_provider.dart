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

    // Tải song song toàn bộ các mục cho nhanh
    final results = await Future.wait([
      _movieService.getHotMovies(limit: 12), // slide: phim hot theo điểm TMDB
      _movieService.getMoviesLimit(12), // phim mới cập nhật
      _movieService.getMoviesByCategory('hanh-dong', limit: 10),
      _movieService.getMoviesByCountry('han-quoc', limit: 12),
      _movieService.getMoviesByCountry('trung-quoc', limit: 12),
      _movieService.getMoviesByCountry('viet-nam', limit: 12),
      _movieService.getMoviesByType('hoathinh', limit: 12),
      _movieService.getMoviesByType('single', limit: 12),
      _movieService.getMoviesByType('series', limit: 12),
      _movieService.getMoviesByCountry('au-my', limit: 10), // phim Âu Mỹ cho slide
    ]);

    await savedMovieNotifier.loadSavedMovies();

    _user = user;
    // Ưu tiên bảng xếp hạng hot; trống thì trộn Á-Âu; vẫn trống thì phim mới
    _featuredMovies = results[0].isNotEmpty
        ? results[0]
        : _mixFeatured(results[1], results[9]);
    if (_featuredMovies.isEmpty) _featuredMovies = results[1];
    _newMovies = results[1];
    _recommendedMovies = results[2];
    _koreanDramas = results[3];
    _chineseDramas = results[4];
    _vietnamMovies = results[5];
    _animationMovies = results[6];
    _singleMovies = results[7];
    _seriesMovies = results[8];
    _continueWatching = await _loadContinueWatching();
    _isLoading = false;
    notifyListeners();
  }

  /// Trộn xen kẽ phim châu Á (2026) và Âu Mỹ cho slide, bỏ trùng, lấy 12.
  List<Movie> _mixFeatured(List<Movie> asian, List<Movie> western) {
    final mixed = <Movie>[];
    final seen = <String>{};
    final maxLen = asian.length > western.length ? asian.length : western.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < asian.length && seen.add(asian[i].slug)) mixed.add(asian[i]);
      if (i < western.length && seen.add(western[i].slug)) mixed.add(western[i]);
    }
    return mixed.take(12).toList();
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
