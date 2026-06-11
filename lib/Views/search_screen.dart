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

  // Bộ lọc phim kiểu kkphim: các trường dropdown + nút "Lọc phim"
  void _showFilterSheet(SearchProvider provider) {
    String category = provider.filterCategory;
    String country = provider.filterCountry;
    String type = provider.filterType;
    int year = provider.filterYear;
    int yearFrom = provider.filterYearFrom;
    int yearTo = provider.filterYearTo;
    String sort = provider.filterSort;
    String lang = provider.filterLang;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            // Một hàng "Nhãn : Dropdown" giống bộ lọc của web kkphim
            Widget dropdownRow<T>({
              required String label,
              required String hint,
              required Map<T, String> options,
              required T? value,
              required T emptyValue,
              required void Function(T) onChanged,
            }) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(label,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: DropdownButtonFormField<T>(
                        initialValue:
                            (value == emptyValue || value == null) ? null : value,
                        isExpanded: true,
                        hint: Text(hint,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500])),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<T>(
                              value: emptyValue, child: Text(hint)),
                          ...options.entries.map(
                            (e) => DropdownMenuItem<T>(
                                value: e.key, child: Text(e.value)),
                          ),
                        ],
                        onChanged: (v) =>
                            setSheetState(() => onChanged(v ?? emptyValue)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final yearMap = {
              for (final y in SearchProvider.yearOptions) y: '$y'
            };

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20,
                  20 + MediaQuery.of(sheetContext).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lọc phim',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            provider.clearFilters();
                          },
                          child: const Text('Xóa lọc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    dropdownRow<String>(
                      label: 'Thể loại',
                      hint: 'Thể loại',
                      options: SearchProvider.categoryOptions,
                      value: category,
                      emptyValue: '',
                      onChanged: (v) => category = v,
                    ),
                    dropdownRow<String>(
                      label: 'Quốc gia',
                      hint: 'Quốc gia',
                      options: SearchProvider.countryOptions,
                      value: country,
                      emptyValue: '',
                      onChanged: (v) => country = v,
                    ),
                    dropdownRow<String>(
                      label: 'Loại phim',
                      hint: 'Loại phim',
                      options: SearchProvider.typeOptions,
                      value: type,
                      emptyValue: '',
                      onChanged: (v) => type = v,
                    ),
                    dropdownRow<int>(
                      label: 'Năm sản xuất',
                      hint: 'Năm sản xuất',
                      options: yearMap,
                      value: year,
                      emptyValue: 0,
                      onChanged: (v) => year = v,
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: 110,
                          child: Text('Khoảng năm',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: yearFrom == 0 ? null : yearFrom,
                            isExpanded: true,
                            hint: Text('Từ',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500])),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                  value: 0, child: Text('Từ')),
                              ...yearMap.entries.map((e) =>
                                  DropdownMenuItem<int>(
                                      value: e.key, child: Text(e.value))),
                            ],
                            onChanged: (v) =>
                                setSheetState(() => yearFrom = v ?? 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: yearTo == 0 ? null : yearTo,
                            isExpanded: true,
                            hint: Text('Đến',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500])),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: [
                              const DropdownMenuItem<int>(
                                  value: 0, child: Text('Đến')),
                              ...yearMap.entries.map((e) =>
                                  DropdownMenuItem<int>(
                                      value: e.key, child: Text(e.value))),
                            ],
                            onChanged: (v) =>
                                setSheetState(() => yearTo = v ?? 0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    dropdownRow<String>(
                      label: 'Sắp xếp theo',
                      hint: 'Sắp xếp theo',
                      options: SearchProvider.sortOptions,
                      value: sort,
                      emptyValue: '',
                      onChanged: (v) => sort = v,
                    ),
                    dropdownRow<String>(
                      label: 'Sub',
                      hint: 'Sub style',
                      options: SearchProvider.langOptions,
                      value: lang,
                      emptyValue: '',
                      onChanged: (v) => lang = v,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _searchController.clear();
                          provider.applyFilters(
                            category: category,
                            country: country,
                            type: type,
                            year: year,
                            yearFrom: yearFrom,
                            yearTo: yearTo,
                            sort: sort,
                            lang: lang,
                          );
                        },
                        child: const Text('Lọc phim'),
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
                      onFilterTap: () => _showFilterSheet(provider),
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
