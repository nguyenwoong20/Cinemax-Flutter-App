// Màn hình tìm kiếm phim, hỗ trợ tìm theo tên hoặc lọc theo danh mục.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Components/bottom_navbar.dart';
import '../Components/search_bar_widget.dart';
import '../Components/category_filter_list.dart';
import '../Components/search_results_grid.dart';
import '../models/movie_model.dart';
import '../providers/search_provider.dart';
import '../utils/app_snackbar.dart';
import 'bookmark_screen.dart';
import 'movie_detail_screen.dart';
import 'profile_screen.dart';
import 'watch_rooms_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SearchProvider? _searchProvider;

  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _searchProvider = SearchProvider();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchProvider?.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = _searchProvider;
    if (provider == null) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isLoading && !provider.isLoadingMore && provider.hasMore) {
        provider.loadMoreMovies();
      }
    }
  }

  Future<void> _toggleSaveMovie(SearchProvider provider, Movie movie) async {
    final action = await provider.toggleSaveMovie(movie);
    if (!mounted) return;

    switch (action) {
      case SearchSaveAction.saved:
        AppSnackBar.showSuccess(context, 'Đã lưu phim thành công');
        break;
      case SearchSaveAction.removed:
        AppSnackBar.showSuccess(context, 'Đã xóa khỏi danh sách lưu');
        break;
      case SearchSaveAction.failed:
        AppSnackBar.showError(context, 'Không thể lưu phim');
        break;
    }
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      Widget destination;
      switch (index) {
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerInstance = _searchProvider ??= SearchProvider();

    return ChangeNotifierProvider<SearchProvider>.value(
      value: providerInstance,
      child: Consumer<SearchProvider>(
        builder: (context, provider, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0E13)
          : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      controller: _searchController,
                      onChanged: provider.onSearchChanged,
                      onFilterTap: () {},
                    ),
                  ),
                ],
              ),
            ),

            CategoryFilterList(
              categories: provider.categories,
              selectedCategory: provider.selectedCategory,
              onCategorySelected: (category) {
                _searchController.clear();
                provider.onCategorySelected(category);
              },
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SearchResultsGrid(
                scrollController: _scrollController,
              movies: provider.movies,
              isLoading: provider.isLoading && provider.movies.isEmpty,
              emptyMessage: provider.searchQuery.isEmpty
                    ? 'Không có phim nào'
                : 'Không tìm thấy kết quả cho "${provider.searchQuery}"',
              isBookmarked: provider.isMovieSaved,
              onBookmark: (movie) => _toggleSaveMovie(provider, movie),
                onMovieTap: (movie) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MovieDetailScreen(movieId: movie.slug, movie: movie),
                    ),
                  );
                },
              ),
            ),

            if (provider.isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
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
