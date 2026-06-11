// Service Singleton quản lý kết nối realtime cho tính năng WatchAlong.
// Backend mới: AWS API Gateway WebSocket API (thay cho Socket.IO server cũ).
// Giao thức: gửi JSON {action, ...data}, nhận JSON {event, ...payload}.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/watch_room_model.dart';
import 'api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocket? _socket;
  bool _connected = false;
  String? _currentRoomCode;
  String? _userId;

  final _onVideoPlayController = StreamController<VideoSyncState>.broadcast();
  final _onVideoPauseController = StreamController<VideoSyncState>.broadcast();
  final _onVideoSeekController = StreamController<VideoSyncState>.broadcast();
  final _onSyncStateController = StreamController<VideoSyncState>.broadcast();
  final _onEpisodeChangeController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onUserJoinedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onUserLeftController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _onRoomClosedController = StreamController<String>.broadcast();
  final _onConnectedController = StreamController<bool>.broadcast();

  Stream<VideoSyncState> get onVideoPlay => _onVideoPlayController.stream;
  Stream<VideoSyncState> get onVideoPause => _onVideoPauseController.stream;
  Stream<VideoSyncState> get onVideoSeek => _onVideoSeekController.stream;
  Stream<VideoSyncState> get onSyncState => _onSyncStateController.stream;
  Stream<Map<String, dynamic>> get onEpisodeChange =>
      _onEpisodeChangeController.stream;
  Stream<Map<String, dynamic>> get onUserJoined =>
      _onUserJoinedController.stream;
  Stream<Map<String, dynamic>> get onUserLeft => _onUserLeftController.stream;
  Stream<String> get onRoomClosed => _onRoomClosedController.stream;
  Stream<bool> get onConnected => _onConnectedController.stream;

  bool get isConnected => _connected;
  String? get currentRoomCode => _currentRoomCode;

  Future<void> connect({String? token}) async {
    if (_connected) return;

    try {
      _socket = await WebSocket.connect(ApiConfig.socketUrl);
      _connected = true;
      _onConnectedController.add(true);

      _socket!.listen(
        (raw) => _handleMessage(raw),
        onDone: () {
          _connected = false;
          _onConnectedController.add(false);
        },
        onError: (error) {
          print('Socket error: $error');
          _connected = false;
          _onConnectedController.add(false);
        },
      );
    } catch (e) {
      print('Socket connect error: $e');
      _connected = false;
      _onConnectedController.add(false);
    }
  }

  void _handleMessage(dynamic raw) {
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(raw as String));
    } catch (_) {
      return;
    }

    switch (data['event']) {
      case 'video-play':
        _onVideoPlayController.add(VideoSyncState.fromJson(data));
        break;
      case 'video-pause':
        _onVideoPauseController.add(VideoSyncState.fromJson(data));
        break;
      case 'video-seek':
        _onVideoSeekController.add(VideoSyncState.fromJson(data));
        break;
      case 'sync-state':
        _onSyncStateController.add(VideoSyncState.fromJson(data));
        break;
      case 'episode-change':
        _onEpisodeChangeController.add(data);
        break;
      case 'user-joined':
        _onUserJoinedController.add(data);
        break;
      case 'user-left':
        _onUserLeftController.add(data);
        break;
      case 'room-closed':
        _onRoomClosedController.add(data['message'] ?? 'Phòng xem chung đã đóng');
        _currentRoomCode = null;
        break;
      case 'error':
        print('Socket server error: ${data['message']}');
        break;
    }
  }

  void _send(Map<String, dynamic> message) {
    if (!_connected || _socket == null) return;
    _socket!.add(jsonEncode(message));
  }

  void disconnect() {
    if (_currentRoomCode != null) {
      leaveRoom(_currentRoomCode!);
    }
    _socket?.close();
    _socket = null;
    _connected = false;
  }

  Future<void> joinRoom(String roomCode, String userId, String userName) async {
    if (!_connected) {
      await connect();
    }

    _currentRoomCode = roomCode;
    _userId = userId;

    _send({
      'action': 'join-room',
      'roomCode': roomCode,
      'userId': userId,
      'userName': userName,
    });
  }

  void leaveRoom(String roomCode) {
    _send({'action': 'leave-room', 'roomCode': roomCode});
    _currentRoomCode = null;
  }

  void emitPlay(double currentTime) {
    if (_currentRoomCode == null) return;
    _send({
      'action': 'video-play',
      'roomCode': _currentRoomCode,
      'currentTime': currentTime,
      'userId': _userId,
    });
  }

  void emitPause(double currentTime) {
    if (_currentRoomCode == null) return;
    _send({
      'action': 'video-pause',
      'roomCode': _currentRoomCode,
      'currentTime': currentTime,
      'userId': _userId,
    });
  }

  void emitSeek(double currentTime) {
    if (_currentRoomCode == null) return;
    _send({
      'action': 'video-seek',
      'roomCode': _currentRoomCode,
      'currentTime': currentTime,
      'userId': _userId,
    });
  }

  void emitEpisodeChange(int serverIndex, int episodeIndex) {
    if (_currentRoomCode == null) return;
    _send({
      'action': 'episode-change',
      'roomCode': _currentRoomCode,
      'serverIndex': serverIndex,
      'episodeIndex': episodeIndex,
      'userId': _userId,
    });
  }

  void requestSync() {
    if (_currentRoomCode == null) return;
    _send({'action': 'sync-request', 'roomCode': _currentRoomCode});
  }

  void closeRoom(String roomCode) {
    _send({'action': 'close-room', 'roomCode': roomCode});
    _currentRoomCode = null;
  }

  void dispose() {
    disconnect();
    _onVideoPlayController.close();
    _onVideoPauseController.close();
    _onVideoSeekController.close();
    _onSyncStateController.close();
    _onEpisodeChangeController.close();
    _onUserJoinedController.close();
    _onUserLeftController.close();
    _onRoomClosedController.close();
    _onConnectedController.close();
  }
}
