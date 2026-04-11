// Màn hình chính của ứng dụng, hiển thị các phim nổi bật, mới và theo danh mục.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Components/bottom_navbar.dart';
import '../Components/home_app_bar.dart';
import '../Components/movie_section.dart';
import '../Components/movie_slide.dart';
import '../providers/home_provider.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
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
          final recommendedMovies = homeProvider.recommendedMovies;
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
                padding: const EdgeInsets.only(top: 8),
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
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Tiếp tục xem',
                movies: newMovies,
                isLoading: isLoading,
                onSeeAll: () {},
                titleIcon: Icons.play_circle_outline,
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Phim mới ra mắt',
                movies: newMovies,
                isLoading: isLoading,
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: MovieSection(
                title: 'Top 10 tại Việt Nam',
                movies: recommendedMovies,
                isLoading: isLoading,
                onSeeAll: () {},
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
