// Component hiển thị ảnh từ mạng có hỗ trợ cache và xử lý proxy cho localhost.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_config.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  // Xây dựng widget ảnh với logic xử lý URL, proxy và placeholder.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl.isEmpty) {
      return _buildPlaceholder(context);
    }

    String finalUrl = imageUrl;

    // Ảnh giờ được host trên S3 (HTTPS) nên tải trực tiếp,
    // không cần đi qua proxy của backend cũ nữa.
    if (finalUrl.startsWith('/')) {
      finalUrl = '${ApiConfig.baseUrl}$finalUrl';
    }

    if (finalUrl.contains('localhost')) {
      finalUrl = finalUrl.replaceFirst('localhost', '10.0.2.2');
    }

    Widget image = CachedNetworkImage(
      imageUrl: finalUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) {
        print('Error loading image $url: $error');
        return _buildPlaceholder(context);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget placeholder = Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[300],
      child: Icon(
        Icons.movie_creation_outlined,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: (width != null && width! < 60) ? 20 : 30,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: placeholder);
    }

    return placeholder;
  }
}
