# Cinemax Flutter App

Ứng dụng xem phim Flutter với các màn hình auth, duyệt phim, chi tiết phim, bookmark và watch room.

## Current Architecture Snapshot

- UI chính đang được tổ chức theo màn hình trong `lib/Views`.
- API/services hiện nằm trong `lib/services`.
- Theme và auth state đã được quản lý bằng Provider.

## Provider Scope Policy

### Global Provider

Use global provider when the state must survive route changes and be shared app-wide.

- `ThemeProvider`
- `AuthProvider`
- `SavedMovieNotifier` or a future global bookmarks provider
- `LocaleProvider` if localization state is added later

### Local Provider

Use local provider when the state belongs to a single screen or a short-lived flow.

- `HomeProvider`
- `SearchProvider`
- `MovieDetailProvider`
- `WatchRoomsProvider`
- `WatchRoomProvider`

### Feature-Scope Provider

Use feature-scope provider when the state is shared by a group of screens inside one feature, but not by the whole app.

- Bookmark state can live here if it is not fully global
- Any multi-screen auth wizard or onboarding flow

### Rule Of Thumb

- If the state must be read by several unrelated routes, keep it global.
- If the state is only for rendering or interaction in one screen, keep it local.
- If the state is shared inside one feature area, prefer feature scope.

## Provider Setup

- App dùng `MultiProvider` tại `lib/main.dart`.
- Các provider hiện tại:
	- `ThemeProvider`: quản lý light/dark mode.
	- `AuthProvider`: quản lý trạng thái đăng nhập, lỗi và loading cho login/login Google.
	- `HomeProvider`: quản lý dữ liệu trang chủ (user, danh sách phim, trạng thái loading, lưu/xóa phim nổi bật).
	- `MovieDetailProvider`: quản lý dữ liệu chi tiết phim, trạng thái loading/error, tiến trình xem và lưu/xóa phim.
	- `SearchProvider`: quản lý tìm kiếm, lọc danh mục, phân trang và trạng thái lưu phim.
	- `WatchRoomsProvider`: quản lý thông tin user, trạng thái join/create room và kết nối socket ban đầu.
	- `WatchRoomProvider`: quản lý trạng thái phiên xem chung (room state, sync event, episode, leave/close room).

## Auth Flow (Provider-first)

- `LoginScreen` không gọi trực tiếp `AuthService` nữa.
- `LoginScreen` gọi `AuthProvider.login()` và `AuthProvider.loginWithGoogle()`.
- Trạng thái loading/error được bind từ provider để UI phản hồi đồng bộ.

## Home Flow (Provider-first)

- `HomeScreen` dùng provider cục bộ cho state trang chủ.
- Logic tải dữ liệu trang chủ đã chuyển sang `HomeProvider.loadData()`.
- Logic lưu/xóa phim ở carousel nổi bật đã chuyển sang `HomeProvider.toggleFeaturedMovieSave()`.

## Movie Detail Flow (Provider-first)

- `MovieDetailScreen` đã chuyển phần lớn state và business logic sang `MovieDetailProvider`.
- Tải chi tiết phim, cast, server/episode, trạng thái lưu phim và tiến trình xem đều được quản lý trong provider.
- UI còn tập trung vào render và điều hướng sang màn phát video.

## Search Flow (Provider-first)

- `SearchScreen` đã chuyển logic search/debounce/filter/pagination vào `SearchProvider`.
- Trạng thái loading/loading more và danh sách kết quả được quản lý tập trung trong provider.
- Bookmark action trong grid được điều phối qua provider để giảm logic trong UI.

## Watch Room Flow (Provider-first)

- `WatchRoomsScreen` đã chuyển logic join/create room và user check sang `WatchRoomsProvider`.
- `WatchRoomScreen` đã chuyển logic đồng bộ socket, trạng thái episode/player và refresh participants sang `WatchRoomProvider`.
- UI chỉ giữ phần hiển thị, điều hướng và xác nhận hành động.

## Next Refactor Steps

- Tách dần theo feature (auth/movie/watch-room).
- Đưa business logic sang domain/use case trước khi thay đổi sâu UI.
- Giữ chiến lược refactor từng phần để tránh ảnh hưởng toàn bộ app.
