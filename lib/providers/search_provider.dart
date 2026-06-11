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

  // Bộ lọc đa tiêu chí kiểu kkphim (thể loại / quốc gia / năm / sắp xếp / sub)
  static const Map<String, String> categoryOptions = {
    'hanh-dong': 'Hành động',
    'phieu-luu': 'Phiêu lưu',
    'hai-huoc': 'Hài hước',
    'hinh-su': 'Hình sự',
    'chinh-kich': 'Chính kịch',
    'gia-dinh': 'Gia đình',
    'lich-su': 'Lịch sử',
    'kinh-di': 'Kinh dị',
    'am-nhac': 'Âm nhạc',
    'bi-an': 'Bí ẩn',
    'tinh-cam': 'Tình cảm',
    'vien-tuong': 'Viễn tưởng',
    'tam-ly': 'Tâm lý',
    'co-trang': 'Cổ trang',
    'vo-thuat': 'Võ thuật',
    'chien-tranh': 'Chiến tranh',
  };
  static const Map<String, String> countryOptions = {
    'au-my': 'Âu Mỹ',
    'han-quoc': 'Hàn Quốc',
    'nhat-ban': 'Nhật Bản',
    'trung-quoc': 'Trung Quốc',
    'hong-kong': 'Hồng Kông',
    'dai-loan': 'Đài Loan',
    'anh': 'Anh',
    'phap': 'Pháp',
    'thai-lan': 'Thái Lan',
    'an-do': 'Ấn Độ',
    'viet-nam': 'Việt Nam',
  };
  static const Map<String, String> typeOptions = {
    'single': 'Phim lẻ',
    'series': 'Phim bộ',
    'hoathinh': 'Hoạt hình',
  };
  static const List<int> yearOptions = [2026, 2025, 2024, 2023, 2022, 2021, 2020];
  static const Map<String, String> sortOptions = {
    '': 'Mới cập nhật',
    'rating': 'Điểm IMDb/TMDB',
    'votes': 'Lượt đánh giá',
    'year': 'Năm sản xuất',
  };
  static const Map<String, String> langOptions = {
    'Vietsub': 'Vietsub',
    'Thuyết Minh': 'Thuyết minh',
    'Lồng Tiếng': 'Lồng tiếng',
  };

  String _filterCategory = '';
  String _filterCountry = '';
  String _filterType = '';
  int _filterYear = 0;
  int _filterYearFrom = 0;
  int _filterYearTo = 0;
  String _filterSort = '';
  String _filterLang = '';

  String get filterCategory => _filterCategory;
  String get filterCountry => _filterCountry;
  String get filterType => _filterType;
  int get filterYear => _filterYear;
  int get filterYearFrom => _filterYearFrom;
  int get filterYearTo => _filterYearTo;
  String get filterSort => _filterSort;
  String get filterLang => _filterLang;
  bool get hasActiveFilter =>
      _filterCategory.isNotEmpty ||
      _filterCountry.isNotEmpty ||
      _filterType.isNotEmpty ||
      _filterYear > 0 ||
      _filterYearFrom > 0 ||
      _filterYearTo > 0 ||
      _filterSort.isNotEmpty ||
      _filterLang.isNotEmpty;

  Future<void> applyFilters({
    String category = '',
    String country = '',
    String type = '',
    int year = 0,
    int yearFrom = 0,
    int yearTo = 0,
    String sort = '',
    String lang = '',
  }) async {
    _filterCategory = category;
    _filterCountry = country;
    _filterType = type;
    _filterYear = year;
    _filterYearFrom = yearFrom;
    _filterYearTo = yearTo;
    _filterSort = sort;
    _filterLang = lang;
    _searchQuery = '';
    _selectedCategory = 'Tất cả';
    notifyListeners();
    await loadMovies();
  }

  Future<void> clearFilters() => applyFilters();

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
    _filterCategory = '';
    _filterCountry = '';
    _filterType = '';
    _filterYear = 0;
    _filterYearFrom = 0;
    _filterYearTo = 0;
    _filterSort = '';
    _filterLang = '';
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

    if (hasActiveFilter) {
      // Backend xử lý mọi tiêu chí trong một lần gọi /api/movies/filter
      return _movieService.getFilteredMovies(
        category: _filterCategory,
        country: _filterCountry,
        type: _filterType,
        year: _filterYear,
        yearFrom: _filterYearFrom,
        yearTo: _filterYearTo,
        lang: _filterLang,
        sort: _filterSort,
        page: page,
        limit: _limit,
      );
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
