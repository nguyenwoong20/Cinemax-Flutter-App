import 'package:flutter/material.dart';

import '../Components/cast_list.dart';
import '../Components/episode_server_list.dart';
import '../models/movie_detail_model.dart';
import '../models/movie_model.dart';
import '../services/history_service.dart';
import '../services/movie_service.dart';
import '../services/saved_movie_service.dart';

enum SaveMovieAction { saved, removed, failed }

class MovieDetailProvider extends ChangeNotifier {
  MovieDetailProvider({
    SavedMovieService? savedMovieService,
    HistoryService? historyService,
    MovieService? movieService,
  }) : _savedMovieService = savedMovieService ?? SavedMovieService(),
       _historyService = historyService ?? HistoryService(),
       _movieService = movieService ?? MovieService();

  final SavedMovieService _savedMovieService;
  final HistoryService _historyService;
  final MovieService _movieService;

  String _movieId = '';
  Movie? _movie;

  bool _isSaved = false;
  bool _isSaveLoading = false;
  bool _isLoading = true;
  String? _errorMessage;

  MovieDetail? _movieDetail;
  List<CastMember> _cast = [];
  List<ServerData> _servers = [];
  int _currentServerIndex = 0;
  int _currentEpisodeIndex = 0;
  MovieProgress? _savedProgress;

  bool get isSaved => _isSaved;
  bool get isSaveLoading => _isSaveLoading;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MovieDetail? get movieDetail => _movieDetail;
  List<CastMember> get cast => _cast;
  List<ServerData> get servers => _servers;
  int get currentServerIndex => _currentServerIndex;
  int get currentEpisodeIndex => _currentEpisodeIndex;
  MovieProgress? get savedProgress => _savedProgress;

  String get slug => _movie?.slug ?? _movieId;

  void initialize({required String movieId, Movie? movie}) {
    _movieId = movieId;
    _movie = movie;
    _checkSaveStatus();
  }

  Future<void> _checkSaveStatus() async {
    _isSaved = await _savedMovieService.isMovieSaved(_movieId);
    notifyListeners();
    await loadMovieDetail();
  }

  Future<void> loadMovieDetail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final movieDetail = await _movieService.getMovieDetailFull(slug);
    final savedProgress = await _historyService.getProgress(slug);

    if (movieDetail != null) {
      _movieDetail = movieDetail;
      _savedProgress = savedProgress;
      _cast = movieDetail.actors.map((name) => CastMember(name: name)).toList();
      _servers = movieDetail.episodes
          .map(
            (server) => ServerData(
              name: server.serverName,
              episodes: server.episodes
                  .map((ep) => EpisodeData(name: ep.name, slug: ep.slug))
                  .toList(),
            ),
          )
          .toList();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = false;
    _errorMessage = 'Không thể tải thông tin phim';
    notifyListeners();
  }

  Future<SaveMovieAction> toggleSaveMovie() async {
    if (_isSaveLoading) {
      return SaveMovieAction.failed;
    }

    _isSaveLoading = true;
    notifyListeners();

    try {
      if (_isSaved) {
        final response = await _savedMovieService.removeSavedMovie(_movieId);
        if (response.success) {
          _isSaved = false;
          _isSaveLoading = false;
          notifyListeners();
          return SaveMovieAction.removed;
        }
      } else {
        final response = await _savedMovieService.saveMovie(_movieId);
        if (response.success) {
          _isSaved = true;
          _isSaveLoading = false;
          notifyListeners();
          return SaveMovieAction.saved;
        }
      }

      _isSaveLoading = false;
      notifyListeners();
      return SaveMovieAction.failed;
    } catch (_) {
      _isSaveLoading = false;
      notifyListeners();
      return SaveMovieAction.failed;
    }
  }

  Future<void> refreshProgress() async {
    _savedProgress = await _historyService.getProgress(slug);
    notifyListeners();
  }

  String get movieName => _movieDetail?.name ?? _movie?.name ?? 'Tên phim';
  String get originName => _movieDetail?.originName ?? _movie?.originName ?? '';
  int get year => _movieDetail?.year ?? _movie?.year ?? 0;
  String get time => _movieDetail?.time ?? _movie?.time ?? '';
  String get quality => _movieDetail?.quality ?? _movie?.quality ?? 'HD';
  String get posterUrl => _movieDetail?.posterUrl ?? _movie?.posterUrl ?? '';
  String get content => _movieDetail?.content ?? _movie?.content ?? 'Chưa có mô tả.';

  List<String> get categoryNames =>
      _movieDetail?.category.map((c) => c.name).toList() ?? _movie?.category ?? [];

  String get firstCategorySlug {
    if (_movieDetail?.category.isNotEmpty == true) {
      return _movieDetail!.category.first.slug;
    }
    return '';
  }
}
