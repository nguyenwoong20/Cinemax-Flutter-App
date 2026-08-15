// Tag điểm IMDb/TMDB màu vàng (★ x.x) đặt ở góc trái trên của poster phim.
import 'package:flutter/material.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  final double fontSize;

  const RatingBadge({super.key, required this.rating, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C518),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: fontSize + 2, color: Colors.black),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
