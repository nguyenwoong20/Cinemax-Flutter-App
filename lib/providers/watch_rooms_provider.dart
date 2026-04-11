import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/watch_room_model.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/watch_room_service.dart';

class WatchRoomsProvider extends ChangeNotifier {
  WatchRoomsProvider({
    WatchRoomService? watchRoomService,
    AuthService? authService,
    SocketService? socketService,
  }) : _watchRoomService = watchRoomService ?? WatchRoomService(),
       _authService = authService ?? AuthService(),
       _socketService = socketService ?? SocketService();

  final WatchRoomService _watchRoomService;
  final AuthService _authService;
  final SocketService _socketService;

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  User? get user => _user;

  Future<void> initialize() async {
    await _checkUser();
    await _connectSocket();
  }

  Future<void> _checkUser() async {
    _user = await _authService.getUser();
    notifyListeners();
  }

  Future<void> _connectSocket() async {
    final token = await _authService.getToken();
    _socketService.connect(token: token);
  }

  Future<WatchRoom?> joinRoom(String roomCode) async {
    if (_user == null) {
      return null;
    }

    _setLoading(true);
    try {
      return await _watchRoomService.joinRoom(roomCode);
    } finally {
      _setLoading(false);
    }
  }

  Future<WatchRoom?> createRoom({
    required String movieSlug,
    required String movieName,
    String? moviePoster,
  }) async {
    _setLoading(true);
    try {
      return await _watchRoomService.createRoom(
        movieSlug: movieSlug,
        movieName: movieName,
        moviePoster: moviePoster,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
