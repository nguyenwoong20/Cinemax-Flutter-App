// Component Video Player tùy chỉnh: tự dựng bộ điều khiển để hỗ trợ
// - 4 chế độ tỉ lệ màn hình (Vừa màn hình / Giãn / Phóng to / Gốc)
// - Tua bằng cách chạm vùng trái/lùi, phải/tiến (tùy chỉnh 5s/10s)
// - Fullscreen xoay ngang, đồng bộ sự kiện cho phòng xem chung.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

enum VideoFitMode { fit, stretch, crop, original }

extension VideoFitModeX on VideoFitMode {
  String get label => switch (this) {
        VideoFitMode.fit => 'Vừa màn hình',
        VideoFitMode.stretch => 'Giãn màn hình',
        VideoFitMode.crop => 'Phóng to / Xén hình',
        VideoFitMode.original => 'Gốc (100%)',
      };

  String get description => switch (this) {
        VideoFitMode.fit => 'Hiện đủ khung hình, có thể có viền đen',
        VideoFitMode.stretch => 'Tràn màn hình, hình có thể bị méo',
        VideoFitMode.crop => 'Lấp đầy màn hình, xén bớt phần rìa',
        VideoFitMode.original => 'Đúng kích thước chuẩn của video',
      };

  IconData get icon => switch (this) {
        VideoFitMode.fit => Icons.fit_screen_outlined,
        VideoFitMode.stretch => Icons.open_in_full,
        VideoFitMode.crop => Icons.crop_free,
        VideoFitMode.original => Icons.crop_original,
      };

  BoxFit get boxFit => switch (this) {
        VideoFitMode.fit => BoxFit.contain,
        VideoFitMode.stretch => BoxFit.fill,
        VideoFitMode.crop => BoxFit.cover,
        VideoFitMode.original => BoxFit.none,
      };
}

enum VideoCommandType { play, pause, seek }

class VideoCommand {
  final VideoCommandType type;
  final Duration? seekPosition;

  VideoCommand.play() : type = VideoCommandType.play, seekPosition = null;
  VideoCommand.pause() : type = VideoCommandType.pause, seekPosition = null;
  VideoCommand.seek(Duration position)
    : type = VideoCommandType.seek,
      seekPosition = position;
}

class CustomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  final void Function(Duration position)? onPlay;
  final void Function(Duration position)? onPause;
  final void Function(Duration position)? onSeek;

  final bool showControls;

  final Stream<VideoCommand>? commandStream;

  final Duration? startAt;
  final void Function(Duration position)? onProgress;

  const CustomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = false,
    this.onPlay,
    this.onPause,
    this.onSeek,
    this.showControls = true,
    this.commandStream,
    this.startAt,
    this.onProgress,
  });

  @override
  State<CustomVideoPlayer> createState() => CustomVideoPlayerState();
}

class CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  bool _isError = false;
  bool _isInitialized = false;

  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;
  bool _isExternalCommand = false;

  // Cài đặt người dùng (lưu bền vững)
  VideoFitMode _fitMode = VideoFitMode.fit;
  int _skipSeconds = 10;
  double _playbackSpeed = 1.0;

  // Trạng thái UI điều khiển
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isFullscreen = false;

  // Hiệu ứng phản hồi khi chạm tua
  int _tapFeedback = 0; // <0 lùi, >0 tiến
  Timer? _feedbackTimer;

  // Route fullscreen là cây widget riêng — cần "cầu nối" để rebuild nó
  StateSetter? _fullscreenSetState;

  // setState cho cả widget gốc lẫn màn fullscreen (nếu đang mở)
  void _refresh(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _fullscreenSetState?.call(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializePlayer();
    widget.commandStream?.listen(_handleExternalCommand);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fitMode = VideoFitMode
          .values[prefs.getInt('player_fit_mode') ?? VideoFitMode.fit.index];
      _skipSeconds = prefs.getInt('player_skip_seconds') ?? 10;
      _playbackSpeed = prefs.getDouble('player_speed') ?? 1.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_fit_mode', _fitMode.index);
    await prefs.setInt('player_skip_seconds', _skipSeconds);
    await prefs.setDouble('player_speed', _playbackSpeed);
  }

  void _setPlaybackSpeed(double speed) {
    _refresh(() => _playbackSpeed = speed);
    _videoPlayerController.setPlaybackSpeed(speed);
    _saveSettings();
  }

  @override
  void didUpdateWidget(CustomVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _disposeController();
    if (_isFullscreen) _exitSystemFullscreen();
    super.dispose();
  }

  void _disposeController() {
    _videoPlayerController.removeListener(_onVideoStateChanged);
    _videoPlayerController.dispose();
    _isInitialized = false;
  }

  // ===== API công khai (giữ tương thích với code cũ) =====
  void play() => _videoPlayerController.play();
  void pause() => _videoPlayerController.pause();
  void seekTo(Duration position) => _videoPlayerController.seekTo(position);
  Duration get currentPosition => _videoPlayerController.value.position;
  bool get isPlaying => _videoPlayerController.value.isPlaying;

  void _handleExternalCommand(VideoCommand command) {
    if (!mounted || !_isInitialized) return;
    _isExternalCommand = true;

    switch (command.type) {
      case VideoCommandType.play:
        _videoPlayerController.play();
        break;
      case VideoCommandType.pause:
        _videoPlayerController.pause();
        break;
      case VideoCommandType.seek:
        if (command.seekPosition != null) {
          _videoPlayerController.seekTo(command.seekPosition!);
        }
        break;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _isExternalCommand = false;
    });
  }

  void _onVideoStateChanged() {
    if (!mounted) return;
    final value = _videoPlayerController.value;

    widget.onProgress?.call(value.position);
    _refresh(() {}); // cập nhật slider/thời gian (cả fullscreen)

    if (_isExternalCommand) return;

    final isPlaying = value.isPlaying;
    final position = value.position;

    if (isPlaying && !_wasPlaying) {
      widget.onPlay?.call(position);
    } else if (!isPlaying && _wasPlaying) {
      widget.onPause?.call(position);
    }

    final positionDiff = (position - _lastPosition).abs();
    if (positionDiff > const Duration(seconds: 2) && _wasPlaying == isPlaying) {
      widget.onSeek?.call(position);
    }

    _wasPlaying = isPlaying;
    _lastPosition = position;
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isError = false;
      _isInitialized = false;
    });

    try {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();

      if (widget.startAt != null && widget.startAt! > Duration.zero) {
        await _videoPlayerController.seekTo(widget.startAt!);
      }

      _videoPlayerController.setLooping(widget.looping);
      _videoPlayerController.addListener(_onVideoStateChanged);

      await _videoPlayerController.setPlaybackSpeed(_playbackSpeed);

      if (widget.autoPlay) {
        await _videoPlayerController.play();
      }

      if (mounted) {
        setState(() => _isInitialized = true);
        _restartHideTimer();
      }
    } catch (e) {
      print('Error initializing video player: $e');
      if (mounted) setState(() => _isError = true);
    }
  }

  // ===== Điều khiển hiển thị =====
  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoPlayerController.value.isPlaying) {
        _refresh(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    _refresh(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _restartHideTimer();
  }

  // ===== Tua bằng CHẠM ĐÚP trái/phải =====
  void _handleDoubleTap(TapDownDetails details, BoxConstraints constraints) {
    if (!widget.showControls || !_isInitialized) return;
    final x = details.localPosition.dx;
    final width = constraints.maxWidth;

    if (x < width * 0.45) {
      _skip(-_skipSeconds);
    } else if (x > width * 0.55) {
      _skip(_skipSeconds);
    }
  }

  void _skip(int seconds) {
    final value = _videoPlayerController.value;
    var target = value.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > value.duration) target = value.duration;
    _videoPlayerController.seekTo(target);

    // hiệu ứng "+10s"/"-10s" thoáng qua
    _feedbackTimer?.cancel();
    _refresh(() => _tapFeedback = seconds);
    _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
      _refresh(() => _tapFeedback = 0);
    });
    if (_controlsVisible) _restartHideTimer();
  }

  // ===== Fullscreen =====
  Future<void> _enterSystemFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _exitSystemFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isFullscreen = true);
    await _enterSystemFullscreen();
    if (!mounted) return;
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, __, ___) => StatefulBuilder(
          builder: (context, setFullscreenState) {
            _fullscreenSetState = setFullscreenState;
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: _buildPlayerArea()),
            );
          },
        ),
      ),
    );
    _fullscreenSetState = null;
    await _exitSystemFullscreen();
    if (mounted) setState(() => _isFullscreen = false);
  }

  // ===== Cài đặt =====
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14181F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void refresh(VoidCallback fn) {
              setSheetState(fn);
            }

            Widget sectionTitle(String text) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                );

            Widget chipRow<T>(
              List<T> options,
              T selected,
              String Function(T) label,
              void Function(T) onSelect,
            ) =>
                Wrap(
                  spacing: 8,
                  children: options.map((o) {
                    final isSelected = o == selected;
                    return ChoiceChip(
                      label: Text(label(o)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF5BA3F5),
                      backgroundColor: const Color(0xFF1A2332),
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontSize: 13),
                      onSelected: (_) {
                        onSelect(o);
                        refresh(() {});
                      },
                    );
                  }).toList(),
                );

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tua nhanh ──
                    sectionTitle('Thời gian tua'),
                    chipRow<int>(
                      [5, 10, 30],
                      _skipSeconds,
                      (s) => '$s giây',
                      (s) {
                        _refresh(() => _skipSeconds = s);
                        _saveSettings();
                      },
                    ),
                    const Divider(color: Colors.white12, height: 24),

                    // ── Tốc độ phát ──
                    sectionTitle('Tốc độ phát'),
                    chipRow<double>(
                      [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
                      _playbackSpeed,
                      (s) => s == 1.0 ? 'Bình thường' : '${s}x',
                      (s) => _setPlaybackSpeed(s),
                    ),
                    const Divider(color: Colors.white12, height: 24),

                    // ── Tỉ lệ màn hình ──
                    sectionTitle('Tỉ lệ màn hình'),
                    ...VideoFitMode.values.map(
                      (mode) => InkWell(
                        onTap: () {
                          _refresh(() => _fitMode = mode);
                          refresh(() {});
                          _saveSettings();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(mode.icon,
                                  color: _fitMode == mode
                                      ? const Color(0xFF5BA3F5)
                                      : Colors.grey[500],
                                  size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mode.label,
                                        style: TextStyle(
                                            color: _fitMode == mode
                                                ? const Color(0xFF5BA3F5)
                                                : Colors.white,
                                            fontSize: 14)),
                                    Text(mode.description,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              if (_fitMode == mode)
                                const Icon(Icons.check,
                                    color: Color(0xFF5BA3F5), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ===== Dựng giao diện =====
  Widget _buildVideoSurface() {
    final size = _videoPlayerController.value.size;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: _fitMode.boxFit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width > 0 ? size.width : 16,
            height: size.height > 0 ? size.height : 9,
            child: VideoPlayer(_videoPlayerController),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onDoubleTapDown: (details) => _handleDoubleTap(details, constraints),
          onDoubleTap: () {}, // bắt buộc đăng ký để onDoubleTapDown hoạt động
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              _buildVideoSurface(),

              // Phản hồi khi chạm tua
              if (_tapFeedback != 0)
                Align(
                  alignment: _tapFeedback < 0
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tapFeedback < 0
                                ? Icons.fast_rewind
                                : Icons.fast_forward,
                            color: Colors.white,
                            size: 26,
                          ),
                          Text(
                            '${_tapFeedback.abs()}s',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Lớp điều khiển
              if (widget.showControls)
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: _buildControls(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    final value = _videoPlayerController.value;
    final position = value.position;
    final duration = value.duration;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.35),
            Colors.transparent,
            Colors.black.withOpacity(0.55),
          ],
        ),
      ),
      child: Column(
        children: [
          // Hàng trên: nút cài đặt
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, right: 6),
              child: IconButton(
                onPressed: _showSettingsSheet,
                icon: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 22),
              ),
            ),
          ),

          // Giữa: lùi / play-pause / tiến
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _skip(-_skipSeconds),
                  icon: Icon(
                    _skipSeconds == 5 ? Icons.replay_5 : Icons.replay_10,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 28),
                IconButton(
                  onPressed: () {
                    value.isPlaying
                        ? _videoPlayerController.pause()
                        : _videoPlayerController.play();
                    _restartHideTimer();
                  },
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(width: 28),
                IconButton(
                  onPressed: () => _skip(_skipSeconds),
                  icon: Icon(
                    _skipSeconds == 5 ? Icons.forward_5 : Icons.forward_10,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),

          // Dưới: thời gian + thanh tua + fullscreen
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 6, 4),
            child: Row(
              children: [
                Text(
                  '${_format(position)} / ${_format(duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: const Color(0xFF5BA3F5),
                      thumbColor: const Color(0xFF5BA3F5),
                      inactiveTrackColor: Colors.white24,
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble()
                          : 0,
                      max: duration.inMilliseconds > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1,
                      onChanged: (v) {
                        _videoPlayerController
                            .seekTo(Duration(milliseconds: v.round()));
                        _restartHideTimer();
                      },
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleFullscreen,
                  icon: Icon(
                    _isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Không thể tải video',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5BA3F5)),
        ),
      );
    }

    // Khi đang fullscreen, widget gốc chỉ giữ nền đen (video hiển thị ở route fullscreen)
    if (_isFullscreen) return Container(color: Colors.black);

    return _buildPlayerArea();
  }
}
