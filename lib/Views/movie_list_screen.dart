// Màn hình "Xem tất cả": lưới phim có phân trang (infinite scroll),
// dùng chung cho mọi mục ở trang chủ (phim mới, theo quốc gia, theo loại...).
import 'package:flutter/material.dart';
import '../Components/cached_image_widget.dart';
import '../Components/rating_badge.dart';
import '../models/movie_model.dart';
import 'movie_detail_screen.dart';

typedef MoviePageLoader = Future<List<Movie>> Function(int page);

class MovieListScreen extends StatefulWidget {
  final String title;
  final MoviePageLoader loader;

  const MovieListScreen({super.key, required this.title, required this.loader});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final List<Movie> _movies = [];
  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    final batch = await widget.loader(_page);

    if (!mounted) return;
    setState(() {
      _movies.addAll(batch);
      _page++;
      _hasMore = batch.length >= 20;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0E13) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDark ? const Color(0xFF0B0E13) : Colors.white,
      ),
      body: _movies.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.49,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
              ),
              itemCount: _movies.length + (_hasMore ? 3 : 0),
              itemBuilder: (context, index) {
                if (index >= _movies.length) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final movie = _movies[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(
                        movieId: movie.slug,
                        movie: movie,
                      ),
                    ),
                  ),
                  // Poster tỉ lệ 2:3 + vùng chữ cao cố định để mọi card đều nhau
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 2 / 3,
                        child: Stack(
                          children: [
                            CachedImageWidget(
                              imageUrl: movie.posterUrl,
                              width: double.infinity,
                              height: double.infinity,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: RatingBadge(rating: movie.rating, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        movie.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${movie.year > 0 ? movie.year : ''} · ${movie.episodeCurrent}'
                            .trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
