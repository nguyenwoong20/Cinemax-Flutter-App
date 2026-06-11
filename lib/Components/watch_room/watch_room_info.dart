// Component hiển thị thông tin phim (tên, server, tập) trong phòng xem chung.
import 'package:flutter/material.dart';

class WatchRoomInfo extends StatelessWidget {
  final String movieName;
  final String? serverName;
  final String? episodeName;

  const WatchRoomInfo({
    super.key,
    required this.movieName,
    this.serverName,
    this.episodeName,
  });

  // Hiển thị tên phim và thông tin tập/server hiện tại.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5BA3F5), Color(0xFF7B6CF6)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'XEM CHUNG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            movieName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          if (serverName != null && episodeName != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      'Đang phát: $episodeName · $serverName',
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
    );
  }
}
