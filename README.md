# 🎬 Cinemax — Movie Streaming App

Ứng dụng xem phim xây dựng bằng **Flutter**, chạy trên backend **100% serverless trên AWS** — không server nào phải bảo trì, chi phí vận hành ≈ $0/tháng với AWS Free Tier.

> 📱 **Tải app:** [Cinemax.apk](https://github.com/nguyenwoong20/Cinemax-Serverless-AWS/raw/main/apk/Cinemax.apk) (~55 MB, Android)

## Kiến trúc hệ thống

![Architecture](https://raw.githubusercontent.com/nguyenwoong20/Cinemax-Serverless-AWS/main/docs/architecture-aws.svg)

**Backend:** 6 Lambda function · 2 API Gateway (REST + WebSocket) · 7 bảng DynamoDB · S3 · EventBridge · CloudWatch — toàn bộ định nghĩa bằng AWS SAM tại repo [Cinemax-Serverless-AWS](https://github.com/nguyenwoong20/Cinemax-Serverless-AWS).

## ✨ Tính năng

### 🎥 Xem phim
- **Kho 260+ phim** lưu trong DynamoDB, poster host trên S3
- **Tự cập nhật phim mới mỗi đêm** (EventBridge cron 2h sáng kéo từ kkphim)
- **Kho tự lớn:** tìm phim chưa có → hệ thống tự tìm trên kkphim và nhập vào kho khi mở xem
- Trình phát video tự xây: **4 chế độ tỉ lệ màn hình** (Vừa / Giãn / Phóng to / Gốc), **chạm đúp trái/phải để tua** (tùy chỉnh 5s/10s), fullscreen xoay ngang, lưu cài đặt
- Lưu tiến độ xem — mục **"Tiếp tục xem"** trên trang chủ

### 🏠 Trang chủ
- Slide **phim hot xếp hạng theo điểm TMDB**, tự xoay vòng bộ phim mới mỗi ngày
- 7 mục phim: Phim mới cập nhật · Drama xứ Kim Chi · Drama "Tàu" · Phim Việt · Hoạt hình · Phim Lẻ · Phim Bộ — đều có "Xem tất cả" với cuộn vô hạn
- **Tag điểm IMDb** trên mọi card phim

### 🔍 Tìm kiếm & Lọc
- Tìm theo tên (có fallback sang kkphim khi kho không có)
- **Bộ lọc đa tiêu chí** kiểu kkphim: thể loại, quốc gia, loại phim, năm, khoảng năm, sub, sắp xếp theo điểm/lượt vote/năm

### 👥 Xem chung (Watch Party)
- Tạo phòng bằng mã 6 ký tự, mời bạn bè vào xem cùng
- **Đồng bộ realtime** play/pause/tua/đổi tập qua **API Gateway WebSocket** — trễ < 1 giây

### 🔐 Tài khoản
- Đăng ký email + **OTP gửi qua email thật**, đăng nhập **Google Sign-In** (Firebase, verify token phía server)
- Đổi tên, **avatar upload lên S3**; tài khoản Google tự ẩn phần mật khẩu
- Phim đã lưu (bookmark) đồng bộ trên cloud

### 💬 Bình luận
- Bình luận theo phim, **tự che từ nhạy cảm** (profanity filter phía server)

### 🎭 Diễn viên
- Ảnh diễn viên thật + tên vai diễn lấy từ **TMDB API**

## 🛠 Tech stack

| Phần | Công nghệ |
|---|---|
| App | Flutter (Dart) · Provider · video_player · WebSocket (dart:io) |
| Auth | Firebase Google Sign-In + JWT tự quản (bcrypt, OTP email) |
| Backend | AWS Lambda (Node.js 22) · API Gateway REST + WebSocket · DynamoDB · S3 · EventBridge · CloudWatch · AWS SAM |
| Dữ liệu phim | kkphim API (phimapi.com) · TMDB API |

## 🚀 Chạy dự án

```bash
git clone https://github.com/nguyenwoong20/Cinemax-Flutter-App.git
cd Cinemax-Flutter-App
flutter pub get
# Cần file android/app/google-services.json từ Firebase Console của bạn
flutter run
```

Endpoint backend cấu hình tại `lib/services/api_config.dart`.

## 📦 Repo liên quan

- ☁️ [Cinemax-Serverless-AWS](https://github.com/nguyenwoong20/Cinemax-Serverless-AWS) — toàn bộ backend (SAM template, 6 Lambda, scripts)
- 📖 [Báo cáo & Workshop](https://nguyenwoong20.github.io/AWS_FCAJ_Workshop/) — tài liệu triển khai song ngữ từng bước
