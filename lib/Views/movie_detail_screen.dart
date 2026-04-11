// Màn hình chi tiết phim, hiển thị thông tin, danh sách diễn viên, tập phim và bình luận.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Components/cast_list.dart';
import '../Components/comment_section.dart';
import '../Components/episode_server_list.dart';
import '../Components/movie_genre_tags.dart';
import '../Components/cached_image_widget.dart';
import '../Components/related_movies_list.dart';
import '../models/movie_model.dart';
import '../providers/movie_detail_provider.dart';
import '../utils/app_snackbar.dart';
import 'video_player_screen.dart';

import '../Components/movie_detail/movie_info_header.dart';
import '../Components/movie_detail/movie_action_buttons.dart';
import '../Components/movie_detail/movie_synopsis.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;
  final Movie? movie;

  const MovieDetailScreen({super.key, required this.movieId, this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  MovieDetailProvider? _provider;

  @override
  void initState() {
    super.initState();
    _provider = MovieDetailProvider()
      ..initialize(movieId: widget.movieId, movie: widget.movie);
  }

  Future<void> _toggleSaveMovie(MovieDetailProvider provider) async {
    final action = await provider.toggleSaveMovie();
    if (!mounted) return;

    switch (action) {
      case SaveMovieAction.saved:
        AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
        break;
      case SaveMovieAction.removed:
        AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
        break;
      case SaveMovieAction.failed:
        AppSnackBar.showError(context, 'Không thể lưu phim');
        break;
    }
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerInstance =
        _provider ??=
            MovieDetailProvider()
              ..initialize(movieId: widget.movieId, movie: widget.movie);

    return ChangeNotifierProvider<MovieDetailProvider>.value(
      value: providerInstance,
      child: Consumer<MovieDetailProvider>(
        builder: (context, provider, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          if (provider.isLoading) {
            return Scaffold(
              backgroundColor: isDark
                  ? const Color(0xFF0B0E13)
                  : const Color(0xFFF5F5F5),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              backgroundColor: isDark
                  ? const Color(0xFF0B0E13)
                  : const Color(0xFFF5F5F5),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: provider.loadMovieDetail,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final posterUrl = provider.posterUrl;
          final movieName = provider.movieName;
          final originName = provider.originName;
          final year = provider.year;
          final time = provider.time;
          final quality = provider.quality;
          final categoryNames = provider.categoryNames;
          final firstCategorySlug = provider.firstCategorySlug;
          final content = provider.content;

          return Scaffold(
            backgroundColor: isDark
                ? const Color(0xFF0B0E13)
                : const Color(0xFFF5F5F5),
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 500,
                  pinned: true,
                  backgroundColor: isDark
                      ? const Color(0xFF0B0E13)
                      : const Color(0xFFF5F5F5),
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: provider.isSaveLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                provider.isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: provider.isSaved
                                    ? const Color(0xFF5BA3F5)
                                    : Colors.white,
                              ),
                              onPressed: () => _toggleSaveMovie(provider),
                            ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          final String deepLink =
                              'https://watchalong428.vercel.app/movie/${provider.slug}';
                          Share.share('Xem phim $movieName tại: $deepLink');
                        },
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedImageWidget(
                          imageUrl: posterUrl.isNotEmpty
                              ? posterUrl
                              : 'https://via.placeholder.com/400x600',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0B0E13).withOpacity(0.7),
                                const Color(0xFF0B0E13),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MovieGenreTags(
                          genres: categoryNames.isNotEmpty
                              ? categoryNames
                              : ['Phim'],
                          rating: 8.5,
                        ),

                        const SizedBox(height: 16),

                        MovieInfoHeader(
                          movieName: movieName,
                          originName: originName,
                          year: year,
                          time: time,
                          quality: quality,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 24),

                        MovieActionButtons(
                          watchText: provider.savedProgress != null
                              ? 'Tiếp tục xem (Tập ${provider.savedProgress!.episodeIndex + 1})'
                              : 'Xem ngay',
                          onWatchPressed: () {
                            if (provider.servers.isNotEmpty &&
                                provider.servers[0].episodes.isNotEmpty) {
                              int startServerIdx = 0;
                              int startEpisodeIdx = 0;
                              Duration? startAt;

                              if (provider.savedProgress != null) {
                                if (provider.savedProgress!.serverIndex <
                                        provider.servers.length &&
                                    provider.savedProgress!.episodeIndex <
                                        provider
                                            .servers[provider
                                                .savedProgress!
                                                .serverIndex]
                                            .episodes
                                            .length) {
                                  startServerIdx =
                                      provider.savedProgress!.serverIndex;
                                  startEpisodeIdx =
                                      provider.savedProgress!.episodeIndex;
                                  if (provider.savedProgress!.positionSeconds >
                                      0) {
                                    startAt = Duration(
                                      seconds:
                                          provider.savedProgress!.positionSeconds,
                                    );
                                  }
                                }
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    movieDetail: provider.movieDetail!,
                                    initialServerIndex: startServerIdx,
                                    initialEpisodeIndex: startEpisodeIdx,
                                    startAt: startAt,
                                  ),
                                ),
                              ).then((_) {
                                provider.refreshProgress();
                              });
                            } else {
                              AppSnackBar.showError(
                                context,
                                'Chưa có tập phim nào',
                              );
                            }
                          },
                          onSavePressed: () => _toggleSaveMovie(provider),
                          isSaved: provider.isSaved,
                          isSaveLoading: provider.isSaveLoading,
                          isDark: isDark,
                        ),

                        const SizedBox(height: 24),

                        MovieSynopsis(content: content, isDark: isDark),

                        const SizedBox(height: 24),

                        EpisodeServerList(
                          servers: provider.servers,
                          currentServerIndex: provider.currentServerIndex,
                          currentEpisodeIndex: provider.currentEpisodeIndex,
                          onEpisodeTap: (serverIndex, episodeIndex) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  movieDetail: provider.movieDetail!,
                                  initialServerIndex: serverIndex,
                                  initialEpisodeIndex: episodeIndex,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        CastList(cast: provider.cast, onSeeAllTap: () {}),

                        const SizedBox(height: 24),

                        CommentSection(movieId: widget.movieId),

                        const SizedBox(height: 24),

                        RelatedMoviesList(
                          categorySlug: firstCategorySlug,
                          currentMovieId: widget.movieId,
                          onMovieTap: (slug) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MovieDetailScreen(movieId: slug),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
