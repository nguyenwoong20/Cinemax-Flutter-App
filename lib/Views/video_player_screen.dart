// Màn hình phát video, bao gồm trình phát phim, danh sách tập và đề xuất.
import 'package:flutter/material.dart';
import '../models/movie_detail_model.dart';
import '../Components/video_player/custom_video_player.dart';
import '../Components/episode_server_list.dart';
import '../Components/comment_section.dart';
import '../services/history_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MovieDetail movieDetail;
  final int initialServerIndex;
  final int initialEpisodeIndex;
  final Duration? startAt;

  const VideoPlayerScreen({
    super.key,
    required this.movieDetail,
    this.initialServerIndex = 0,
    this.initialEpisodeIndex = 0,
    this.startAt,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _currentServerIndex;
  late int _currentEpisodeIndex;
  late List<ServerData> _servers;
  final HistoryService _historyService = HistoryService();
  int _lastSaveTime = 0;

  @override
  void initState() {
    super.initState();
    _currentServerIndex = widget.initialServerIndex;
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _convertEpisodes();
  }

  void _onProgress(Duration position) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSaveTime > 15000) {
      _saveProgress(position);
      _lastSaveTime = now;
    }
  }

  void _saveProgress(Duration position) {
    if (position.inSeconds < 5) return;

    _historyService.saveProgress(
      MovieProgress(
        movieSlug: widget.movieDetail.slug,
        serverIndex: _currentServerIndex,
        episodeIndex: _currentEpisodeIndex,
        positionSeconds: position.inSeconds,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _convertEpisodes() {
    _servers = widget.movieDetail.episodes
        .map(
          (server) => ServerData(
            name: server.serverName,
            episodes: server.episodes
                .map(
                  (ep) => EpisodeData(
                    name: ep.name,
                    slug: ep.slug,
                    linkEmbed: ep.linkEmbed,
                    linkM3u8: ep.linkM3u8,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Widget _buildBadge(String text, Color color, {bool filled = false}) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNoSourcePlaceholder() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_bottom,
              color: Color(0xFF5BA3F5), size: 44),
          const SizedBox(height: 14),
          const Text(
            'Ôi hỏng rồi 😥\nKhông thể tải video hoặc chưa có bản đẹp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tập phim này bị hỏng hoặc chưa có bản đẹp.\nXin bạn hãy đợi nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    final currentEpisode = currentServer.episodes[_currentEpisodeIndex];

    // link_m3u8 là stream trực tiếp (HLS) phát được; link_embed chỉ là trang
    // iframe nên video_player không mở được → coi như tập chưa có bản đẹp.
    final bool hasDirectSource = currentEpisode.linkM3u8.isNotEmpty;
    final String videoUrl = currentEpisode.linkM3u8;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Builder(builder: (context) {
              final size = MediaQuery.of(context).size;
              final videoHeight = (size.width * 9 / 16)
                  .clamp(0.0, size.height * 0.55);
              return SizedBox(
                width: double.infinity,
                height: videoHeight,
                child: Stack(
                children: [
                  hasDirectSource
                      ? CustomVideoPlayer(
                          key: ValueKey(
                            '${_currentServerIndex}_$_currentEpisodeIndex',
                          ),
                          videoUrl: videoUrl,
                          autoPlay: true,
                          startAt:
                              (_currentServerIndex ==
                                          widget.initialServerIndex &&
                                      _currentEpisodeIndex ==
                                          widget.initialEpisodeIndex)
                                  ? widget.startAt
                                  : null,
                          onProgress: _onProgress,
                        )
                      : _buildNoSourcePlaceholder(),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              );
            }),

            Expanded(
              // Màn phát phim luôn nền đen nên ép theme tối cho mọi widget con
              // (chip tập, bình luận...) — tránh chip sáng chói khi máy ở light mode.
              child: Theme(
                data: ThemeData.dark(useMaterial3: true).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF5BA3F5),
                    surface: Color(0xFF14181F),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.movieDetail.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            if (widget.movieDetail.originName.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.movieDetail.originName,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildBadge(
                                  widget.movieDetail.quality,
                                  const Color(0xFF5BA3F5),
                                  filled: true,
                                ),
                                _buildBadge(widget.movieDetail.lang,
                                    Colors.grey[400]!),
                                if (widget.movieDetail.year > 0)
                                  _buildBadge('${widget.movieDetail.year}',
                                      Colors.grey[400]!),
                                if (widget.movieDetail.episodeCurrent.isNotEmpty)
                                  _buildBadge(widget.movieDetail.episodeCurrent,
                                      Colors.grey[400]!),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5BA3F5).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_circle_fill,
                                      size: 16, color: Color(0xFF5BA3F5)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Đang phát: ${currentEpisode.name} · ${currentServer.serverName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF5BA3F5),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(color: Colors.white.withOpacity(0.08), height: 1),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: EpisodeServerList(
                          servers: _servers,
                          currentServerIndex: _currentServerIndex,
                          currentEpisodeIndex: _currentEpisodeIndex,
                          onEpisodeTap: (serverIdx, episodeIdx) {
                            setState(() {
                              _currentServerIndex = serverIdx;
                              _currentEpisodeIndex = episodeIdx;
                            });
                          },
                        ),
                      ),

                      Divider(color: Colors.white.withOpacity(0.08), height: 1),

                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: CommentSection(movieId: widget.movieDetail.slug),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
