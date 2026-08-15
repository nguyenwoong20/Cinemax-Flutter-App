// Màn hình phòng xem chung, hỗ trợ đồng bộ video và chat giữa các thành viên.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/watch_room_model.dart';
import '../providers/watch_room_provider.dart';
import '../utils/app_snackbar.dart';

import '../Components/watch_room/watch_room_player.dart';
import '../Components/watch_room/watch_room_info.dart';
import '../Components/watch_room/watch_room_participants.dart';
import '../Components/watch_room/watch_room_episode_list.dart';

class WatchRoomScreen extends StatefulWidget {
  final WatchRoom room;
  final bool isHost;

  const WatchRoomScreen({super.key, required this.room, required this.isHost});

  @override
  State<WatchRoomScreen> createState() => _WatchRoomScreenState();
}

class _WatchRoomScreenState extends State<WatchRoomScreen> {
  WatchRoomProvider? _watchRoomProvider;

  @override
  void initState() {
    super.initState();
    _watchRoomProvider = WatchRoomProvider()
      ..initialize(room: widget.room, isHost: widget.isHost);
  }

  void _consumeProviderEffects(WatchRoomProvider provider) {
    if (provider.infoMessage == null &&
        provider.warningMessage == null &&
        !provider.shouldCloseScreen) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (provider.infoMessage != null) {
        AppSnackBar.showInfo(context, provider.infoMessage!);
      }

      if (provider.warningMessage != null) {
        AppSnackBar.showWarning(context, provider.warningMessage!);
      }

      if (provider.shouldCloseScreen) {
        Navigator.pop(context);
      }

      provider.consumeTransientMessages();
    });
  }

  Future<void> _leaveRoom(WatchRoomProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.isHost ? 'Đóng phòng?' : 'Rời phòng?'),
        content: Text(
          provider.isHost
              ? 'Đóng phòng sẽ kết thúc phiên xem cho tất cả mọi người.'
              : 'Bạn có chắc muốn rời phòng?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(provider.isHost ? 'Đóng phòng' : 'Rời phòng'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await provider.leaveRoom();
      Navigator.pop(context);
    }
  }

  void _onEpisodeTap(WatchRoomProvider provider, int index) {
    final changed = provider.changeEpisode(index);
    if (!changed) {
      AppSnackBar.showWarning(context, 'Chỉ host mới có thể đổi tập');
    }
  }

  @override
  void dispose() {
    _watchRoomProvider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerInstance = _watchRoomProvider ??= WatchRoomProvider()
      ..initialize(room: widget.room, isHost: widget.isHost);

    return ChangeNotifierProvider<WatchRoomProvider>.value(
      value: providerInstance,
      child: Consumer<WatchRoomProvider>(
        builder: (context, provider, child) {
          _consumeProviderEffects(provider);

          final room = provider.room;
          final movieDetail = provider.movieDetail;

          if (provider.isLoading || room == null) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: const SafeArea(
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
                children: [
                  WatchRoomPlayer(
                    videoUrl: provider.currentVideoUrl,
                    isHost: provider.isHost,
                    roomCode: room.roomCode,
                    initialTime: room.currentTime,
                    socketService: provider.socketService,
                    showSyncIndicator: provider.showSyncIndicator,
                    syncIndicatorIcon: provider.syncIndicatorIcon,
                    onLeave: () => _leaveRoom(provider),
                    playerKey: provider.playerKey,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (movieDetail != null &&
                              movieDetail.episodes.isNotEmpty)
                            WatchRoomInfo(
                              movieName: room.movieName,
                              serverName: movieDetail
                                  .episodes[provider.currentServerIndex]
                                  .serverName,
                              episodeName: movieDetail
                                  .episodes[provider.currentServerIndex]
                                  .episodes[provider.currentEpisodeIndex]
                                  .name,
                            ),

                          const Divider(color: Colors.grey, height: 1),

                          WatchRoomParticipants(
                            participants: room.participants,
                            hostId: room.hostId,
                          ),

                          const Divider(color: Colors.grey, height: 1),

                            if (movieDetail != null &&
                              movieDetail.episodes.isNotEmpty)
                            WatchRoomEpisodeList(
                              episodes: movieDetail
                                .episodes[provider.currentServerIndex]
                                  .episodes,
                              currentEpisodeIndex: provider.currentEpisodeIndex,
                              isHost: provider.isHost,
                              onEpisodeTap: (index) =>
                                _onEpisodeTap(provider, index),
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
          );
        },
      ),
    );
  }
}
