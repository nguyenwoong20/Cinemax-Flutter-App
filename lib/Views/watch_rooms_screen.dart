// Màn hình danh sách các phòng xem chung, cho phép tạo mới hoặc tham gia.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Components/bottom_navbar.dart';
import '../providers/watch_rooms_provider.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watch_room_screen.dart';

import '../Components/watch_room/join_room_section.dart';
import '../Components/watch_room/create_room_modal.dart';

class WatchRoomsScreen extends StatefulWidget {
  const WatchRoomsScreen({super.key});

  @override
  State<WatchRoomsScreen> createState() => _WatchRoomsScreenState();
}

class _WatchRoomsScreenState extends State<WatchRoomsScreen> {
  WatchRoomsProvider? _watchRoomsProvider;
  final int _currentNavIndex = 3;

  @override
  void initState() {
    super.initState();
    _watchRoomsProvider = WatchRoomsProvider()..initialize();
  }

  @override
  void dispose() {
    _watchRoomsProvider?.dispose();
    super.dispose();
  }

  void _onJoinRoom(WatchRoomsProvider provider, String roomCode) async {
    if (provider.user == null) {
      AppSnackBar.showWarning(context, 'Vui lòng đăng nhập để tham gia');
      return;
    }

    try {
      final room = await provider.joinRoom(roomCode);

      if (!mounted) return;

      if (room != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WatchRoomScreen(
                  room: room,
                  isHost: room.hostId == provider.user!.id,
                ),
          ),
        );
      } else {
        AppSnackBar.showError(
          context,
          'Không tìm thấy phòng hoặc phòng đã đầy',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Lỗi kết nối: $e');
      }
    }
  }

  void _showCreateRoomDialog(WatchRoomsProvider provider) {
    if (provider.user == null) {
      AppSnackBar.showWarning(context, 'Vui lòng đăng nhập để tạo phòng');
      return;
    }

    CreateRoomModal.show(
      context,
      onCreate: (slug, name, poster) async {
        Navigator.pop(context);
        await _createRoom(provider, slug, name, poster);
      },
    );
  }

  Future<void> _createRoom(
    WatchRoomsProvider provider,
    String movieSlug,
    String movieName,
    String? moviePoster,
  ) async {
    final room = await provider.createRoom(
      movieSlug: movieSlug,
      movieName: movieName,
      moviePoster: moviePoster,
    );

    if (mounted) {
      if (room != null) {
        AppSnackBar.showSuccess(context, 'Đã tạo phòng: ${room.roomCode}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WatchRoomScreen(room: room, isHost: true),
          ),
        );
      } else {
        AppSnackBar.showError(context, 'Không thể tạo phòng');
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentNavIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const SearchScreen();
        break;
      case 2:
        destination = const BookmarkScreen();
        break;
      case 3:
        return;
      case 4:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerInstance = _watchRoomsProvider ??= WatchRoomsProvider()
      ..initialize();

    return ChangeNotifierProvider<WatchRoomsProvider>.value(
      value: providerInstance,
      child: Consumer<WatchRoomsProvider>(
        builder: (context, provider, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Xem chung',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA3F5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.screen_share_rounded,
                  size: 64,
                  color: Color(0xFF5BA3F5),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Xem phim cùng bạn bè',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo phòng hoặc nhập mã để bắt đầu',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),
              JoinRoomSection(
                onJoin: (roomCode) => _onJoinRoom(provider, roomCode),
                isLoading: provider.isLoading,
              ),
              const SizedBox(height: 32),

              TextButton.icon(
                onPressed: () => _showCreateRoomDialog(provider),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tạo phòng mới'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF5BA3F5),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentNavIndex,
        onTap: _onNavBarTap,
      ),
          );
        },
      ),
    );
  }
}
