// Màn hình chính của ứng dụng, hiển thị các phim nổi bật, mới và theo danh mục.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Components/bottom_navbar.dart';
import '../Components/home_app_bar.dart';
import '../Components/movie_section.dart';
import '../Components/movie_slide.dart';
import '../providers/home_provider.dart';
import '../services/movie_service.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'movie_list_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'watch_rooms_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  HomeProvider? _homeProvider;
  final MovieService _movieService = MovieService();

  void _openList(String title, MoviePageLoader loader) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieListScreen(title: title, loader: loader),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _homeProvider = HomeProvider()..loadData();
  }

  Future<void> _toggleSaveMovie(HomeProvider homeProvider, int index) async {
    final action = await homeProvider.toggleFeaturedMovieSave(index);

    if (!mounted) return;

    switch (action) {
      case SaveMovieAction.removed:
        AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
        break;
      case SaveMovieAction.saved:
        AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
        break;
      case SaveMovieAction.failed:
        AppSnackBar.showError(context, 'Không thể lưu phim');
        break;
    }
  }

  @override
  void dispose() {
    _homeProvider?.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        return;
      case 1:
        destination = const SearchScreen();
        break;
      case 2:
        destination = const BookmarkScreen();
        break;
      case 3:
        destination = const WatchRoomsScreen();
        break;
      case 4:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerInstance = _homeProvider ??= HomeProvider()..loadData();

    return ChangeNotifierProvider<HomeProvider>.value(
      value: providerInstance,
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final featuredMovies = homeProvider.featuredMovies;
          final newMovies = homeProvider.newMovies;
          final isLoading = homeProvider.isLoading;

          final featuredSavedStates = featuredMovies
              .map((m) => homeProvider.isMovieSaved(m.slug))
              .toList();

          return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            HomeAppBar(user: homeProvider.user),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '🔥 Hot Trending',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.zero,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : MovieSlide(
                        movies: featuredMovies
                            .map(
                              (m) => {
                                'title': m.name,
                                'year': m.year.toString(),
                                'genre': m.type,
                                'image': m.posterUrl,
                              },
                            )
                            .toList(),
                        bookmarkedStates: featuredSavedStates,
                        onBookmark: (index) =>
                            _toggleSaveMovie(homeProvider, index),
                        onMovieTap: (index) {
                          final movie = featuredMovies[index];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(
                                movieId: movie.slug,
                                movie: movie,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (homeProvider.continueWatching.isNotEmpty)
              SliverToBoxAdapter(
                child: MovieSection(
                  title: 'Tiếp tục xem',
                  movies: homeProvider.continueWatching,
                  isLoading: isLoading,
                  onSeeAll: () => _openList(
                    'Tiếp tục xem',
                    (page) async =>
                        page == 1 ? homeProvider.continueWatching : [],
                  ),
                  titleIcon: Icons.play_circle_outline,
                  onRemove: (movie) =>
                      homeProvider.removeFromContinueWatching(movie.slug),
                ),
              ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Phim mới cập nhật',
                movies: newMovies,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Phim mới cập nhật',
                  (page) => _movieService.searchMovies('', page: page),
                ),
                titleIcon: Icons.fiber_new_outlined,
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Drama xứ Kim Chi',
                movies: homeProvider.koreanDramas,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Drama xứ Kim Chi',
                  (page) => _movieService.getMoviesByCountry('han-quoc', page: page),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Trường thiên Drama "Tàu"',
                movies: homeProvider.chineseDramas,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Trường thiên Drama "Tàu"',
                  (page) => _movieService.getMoviesByCountry('trung-quoc', page: page),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Xưởng Phim Xứ Đông Lào',
                movies: homeProvider.vietnamMovies,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Xưởng Phim Xứ Đông Lào',
                  (page) => _movieService.getMoviesByCountry('viet-nam', page: page),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Xi nê tuổi thơ',
                movies: homeProvider.animationMovies,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Xi nê tuổi thơ',
                  (page) => _movieService.getMoviesByType('hoathinh', page: page),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Phim Lẻ Mới Nhất',
                movies: homeProvider.singleMovies,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Phim Lẻ Mới Nhất',
                  (page) => _movieService.getMoviesByType('single', page: page),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Phim Bộ Mới Nhất',
                movies: homeProvider.seriesMovies,
                isLoading: isLoading,
                onSeeAll: () => _openList(
                  'Phim Bộ Mới Nhất',
                  (page) => _movieService.getMoviesByType('series', page: page),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
          );
        },
      ),
    );
  }
}
