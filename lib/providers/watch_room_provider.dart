import 'dart:async';

import 'package:flutter/material.dart';

import '../models/movie_detail_model.dart';
import '../models/user_model.dart';
import '../models/watch_room_model.dart';
import '../services/auth_service.dart';
import '../services/movie_service.dart';
import '../services/socket_service.dart';
import '../services/watch_room_service.dart';

class WatchRoomProvider extends ChangeNotifier {
  WatchRoomProvider({
    SocketService? socketService,
    WatchRoomService? watchRoomService,
    AuthService? authService,
    MovieService? movieService,
  }) : _socketService = socketService ?? SocketService(),
       _watchRoomService = watchRoomService ?? WatchRoomService(),
       _authService = authService ?? AuthService(),
       _movieService = movieService ?? MovieService();

  final SocketService _socketService;
  final WatchRoomService _watchRoomService;
  final AuthService _authService;
  final MovieService _movieService;

  final List<StreamSubscription> _subscriptions = [];

  WatchRoom? _room;
  User? _user;
  MovieDetail? _movieDetail;
  bool _isLoading = true;
  bool _isHost = false;

  String? _currentVideoUrl;
  int _currentServerIndex = 0;
  int _currentEpisodeIndex = 0;

  Key _playerKey = UniqueKey();
  bool _isSyncing = false;
  bool _showSyncIndicator = false;
  IconData _syncIndicatorIcon = Icons.play_arrow;

  String? _infoMessage;
  String? _warningMessage;
  bool _shouldCloseScreen = false;

  WatchRoom? get room => _room;
  User? get user => _user;
  MovieDetail? get movieDetail => _movieDetail;
  bool get isLoading => _isLoading;
  bool get isHost => _isHost;
  String? get currentVideoUrl => _currentVideoUrl;
  int get currentServerIndex => _currentServerIndex;
  int get currentEpisodeIndex => _currentEpisodeIndex;
  Key get playerKey => _playerKey;
  bool get showSyncIndicator => _showSyncIndicator;
  IconData get syncIndicatorIcon => _syncIndicatorIcon;
  SocketService get socketService => _socketService;
  String? get infoMessage => _infoMessage;
  String? get warningMessage => _warningMessage;
  bool get shouldCloseScreen => _shouldCloseScreen;

  Future<void> initialize({required WatchRoom room, required bool isHost}) async {
    _room = room;
    _isHost = isHost;
    _currentServerIndex = room.currentServer;
    _currentEpisodeIndex = room.currentEpisode;

    _user = await _authService.getUser();
    _movieDetail = await _movieService.getMovieDetailFull(room.movieSlug);

    if (_movieDetail != null) {
      _updateVideoUrl();
    }

    final token = await _authService.getToken();
    _socketService.connect(token: token);

    if (_user != null) {
      _socketService.joinRoom(
        room.roomCode,
        _user!.id,
        _user!.name.isNotEmpty ? _user!.name : _user!.email,
      );
    }

    _setupSocketListeners();
    _isLoading = false;
    notifyListeners();
  }

  void _setupSocketListeners() {
    _subscriptions.add(
      _socketService.onSyncState.listen((state) {
        if (_isSyncing) return;
        _currentServerIndex = state.currentServer;
        _currentEpisodeIndex = state.currentEpisode;
        _updateVideoUrl();
        notifyListeners();
      }),
    );

    if (!_isHost) {
      _subscriptions.add(
        _socketService.onVideoPlay.listen((_) {
          _showSyncIcon(Icons.play_arrow);
        }),
      );

      _subscriptions.add(
        _socketService.onVideoPause.listen((_) {
          _showSyncIcon(Icons.pause);
        }),
      );

      _subscriptions.add(
        _socketService.onVideoSeek.listen((_) {
          _showSyncIcon(Icons.fast_forward);
        }),
      );
    }

    _subscriptions.add(
      _socketService.onEpisodeChange.listen((data) {
        if (_isSyncing) return;
        _currentServerIndex = data['serverIndex'] as int;
        _currentEpisodeIndex = data['episodeIndex'] as int;
        _updateVideoUrl();
        _playerKey = UniqueKey();
        _infoMessage = 'Đổi tập phim';
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _socketService.onUserJoined.listen((data) {
        final userName = data['userName'] ?? 'Ai đó';
        _infoMessage = '$userName đã tham gia';
        _refreshRoom();
      }),
    );

    _subscriptions.add(
      _socketService.onUserLeft.listen((_) {
        _refreshRoom();
      }),
    );

    _subscriptions.add(
      _socketService.onRoomClosed.listen((message) {
        _warningMessage = message;
        _shouldCloseScreen = true;
        notifyListeners();
      }),
    );
  }

  void consumeTransientMessages() {
    _infoMessage = null;
    _warningMessage = null;
    _shouldCloseScreen = false;
  }

  void _showSyncIcon(IconData icon) {
    _showSyncIndicator = true;
    _syncIndicatorIcon = icon;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 1500), () {
      _showSyncIndicator = false;
      notifyListeners();
    });
  }

  void _updateVideoUrl() {
    if (_movieDetail == null || _movieDetail!.episodes.isEmpty) return;

    final server = _movieDetail!.episodes[_currentServerIndex];
    if (server.episodes.isEmpty) return;

    final episode = server.episodes[_currentEpisodeIndex];
    _currentVideoUrl = episode.linkM3u8.isNotEmpty ? episode.linkM3u8 : episode.linkEmbed;
  }

  Future<void> _refreshRoom() async {
    if (_room == null) return;

    final latest = await _watchRoomService.getRoom(_room!.roomCode);
    if (latest != null) {
      _room = latest;
      notifyListeners();
    }
  }

  Future<void> leaveRoom() async {
    if (_room == null) return;

    if (_isHost) {
      _socketService.closeRoom(_room!.roomCode);
      await _watchRoomService.closeRoom(_room!.roomCode);
    } else {
      _socketService.leaveRoom(_room!.roomCode);
      await _watchRoomService.leaveRoom(_room!.roomCode);
    }
  }

  bool changeEpisode(int index) {
    if (!_isHost) {
      return false;
    }

    _isSyncing = true;
    _currentEpisodeIndex = index;
    _updateVideoUrl();
    _playerKey = UniqueKey();
    _socketService.emitEpisodeChange(_currentServerIndex, index);
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isSyncing = false;
    });

    return true;
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }

    if (_room != null) {
      _socketService.leaveRoom(_room!.roomCode);
    }
    super.dispose();
  }
}
