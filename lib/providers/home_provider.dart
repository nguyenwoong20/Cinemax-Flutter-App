import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = true;

  User? get user => _user;
  List<Movie> get featuredMovies => _featuredMovies;
  List<Movie> get newMovies => _newMovies;
  List<Movie> get recommendedMovies => _recommendedMovies;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.getUser();
    final featured = await _movieService.getMoviesLimit(5);
    final newRelease = await _movieService.getMoviesByYear(2025, limit: 10);
    final recommended = await _movieService.getMoviesByCategory(
      'hanh-dong',
      limit: 10,
    );

    await savedMovieNotifier.loadSavedMovies();

    _user = user;
    _featuredMovies = featured;
    _newMovies = newRelease;
    _recommendedMovies = recommended;
    _isLoading = false;
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
