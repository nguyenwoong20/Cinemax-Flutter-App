import 'dart:async';

import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_notifier.dart';

enum SearchSaveAction { saved, removed, failed }

class SearchProvider extends ChangeNotifier {
  SearchProvider({MovieService? movieService})
    : _movieService = movieService ?? MovieService() {
    _categories = _categorySlugs.keys.toList();
    savedMovieNotifier.addListener(_onSavedMoviesChanged);

    if (!savedMovieNotifier.isLoaded) {
      savedMovieNotifier.loadSavedMovies();
    }

    loadMovies();
  }

  final MovieService _movieService;

  final Map<String, String> _categorySlugs = {
    'Tất cả': '',
    'Hành động': 'hanh-dong',
    'Tình cảm': 'tinh-cam',
    'Kinh dị': 'kinh-di',
    'Hoạt hình': 'hoat-hinh',
    'Viễn tưởng': 'vien-tuong',
  };

  late final List<String> _categories;
  List<String> get categories => _categories;

  List<Movie> _movies = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';

  int _currentPage = 1;
  bool _hasMore = true;
  static const int _limit = 20;

  Timer? _debounce;

  List<Movie> get movies => _movies;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get hasMore => _hasMore;

  Future<void> loadMovies() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final newMovies = await _fetchMovies(page: 1);
      _movies = newMovies;
      _currentPage = 1;
      _hasMore = newMovies.length >= _limit;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMovies() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final newMovies = await _fetchMovies(page: nextPage);
      _movies = [..._movies, ...newMovies];
      _currentPage = nextPage;
      _hasMore = newMovies.length >= _limit;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _searchQuery = query;
    notifyListeners();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      loadMovies();
    });
  }

  Future<void> onCategorySelected(String category) async {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _searchQuery = '';
    notifyListeners();

    await loadMovies();
  }

  bool isMovieSaved(Movie movie) {
    return savedMovieNotifier.isMovieSaved(movie.slug);
  }

  Future<SearchSaveAction> toggleSaveMovie(Movie movie) async {
    final slug = movie.slug;
    final isCurrentlySaved = savedMovieNotifier.isMovieSaved(slug);

    if (isCurrentlySaved) {
      final success = await savedMovieNotifier.removeSavedMovie(slug);
      return success ? SearchSaveAction.removed : SearchSaveAction.failed;
    }

    final success = await savedMovieNotifier.saveMovie(slug);
    return success ? SearchSaveAction.saved : SearchSaveAction.failed;
  }

  Future<List<Movie>> _fetchMovies({required int page}) async {
    if (_searchQuery.isNotEmpty) {
      return _movieService.searchMovies(_searchQuery, page: page, limit: _limit);
    }

    if (_selectedCategory == 'Tất cả') {
      return _movieService.searchMovies('', page: page, limit: _limit);
    }

    final slug = _categorySlugs[_selectedCategory]!;
    return _movieService.getMoviesByCategory(slug, page: page, limit: _limit);
  }

  void _onSavedMoviesChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    savedMovieNotifier.removeListener(_onSavedMoviesChanged);
    super.dispose();
  }
}
