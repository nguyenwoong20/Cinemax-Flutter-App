// Cấu hình API endpoints và hằng số hệ thống.
class ApiConfig {
  static const String localBaseUrl = 'http://192.168.1.45:4000';
  static const String awsBaseUrl =
      'https://c0ocqpmzj9.execute-api.ap-southeast-1.amazonaws.com/prod';

  // Toggle: true = local server, false = AWS
  static bool useLocal = false;

  static String get baseUrl => useLocal ? localBaseUrl : awsBaseUrl;

  static const String authEndpoint = '/api/auth';
  static const String userEndpoint = '/api/user';
  static const String commentEndpoint = '/api/comments';
  static const String movieEndpoint = '/api/movies';

  static String get registerUrl => '$baseUrl$authEndpoint/register';
  static String get loginUrl => '$baseUrl$authEndpoint/login';
  static String get verifyEmailUrl => '$baseUrl$authEndpoint/verify-email';
  static String get googleLoginUrl => '$baseUrl$authEndpoint/google-login';
  static String get resendVerifyOtpUrl =>
      '$baseUrl$authEndpoint/resend-verify-otp';
  static String get forgotPasswordUrl =>
      '$baseUrl$authEndpoint/forgot-password';
  static String get resetPasswordUrl => '$baseUrl$authEndpoint/reset-password';

  static String updateUserUrl(String userId) =>
      '$baseUrl$userEndpoint/$userId';

  static String getCommentsUrl(String movieId) =>
      '$baseUrl$commentEndpoint/$movieId';
  static String get addCommentUrl => '$baseUrl$commentEndpoint/add';

  static String getMoviesLimitUrl(int limit) =>
      '$baseUrl$movieEndpoint/limit/$limit';
  static String getMoviesByCategoryUrl(String slug) =>
      '$baseUrl$movieEndpoint/category/$slug';
  static String getMoviesByCountryUrl(String slug) =>
      '$baseUrl$movieEndpoint/country/$slug';
  static String getMoviesByYearUrl(int year) =>
      '$baseUrl$movieEndpoint/year/$year';

  // Các endpoints mới từ nhánh feature
  static String getMoviesByTypeUrl(String type) =>
      '$baseUrl$movieEndpoint/type/$type';
  static String get hotMoviesUrl => '$baseUrl$movieEndpoint/hot';
  static String get homeDataUrl => '$baseUrl$movieEndpoint/home';
  static String get filterMoviesUrl => '$baseUrl$movieEndpoint/filter';
  static String getMovieDetailUrl(String slug) =>
      '$baseUrl$movieEndpoint/$slug';
  static String getMovieCastUrl(String slug) =>
      '$baseUrl$movieEndpoint/$slug/cast';

  static String get searchMoviesUrl => '$baseUrl$movieEndpoint';

  static const String bookmarkEndpoint = '/api/bookmarks';
  static String get getBookmarksUrl => '$baseUrl$bookmarkEndpoint';
  static String get addBookmarkUrl => '$baseUrl$bookmarkEndpoint';
  static String removeBookmarkUrl(String movieId) =>
      '$baseUrl$bookmarkEndpoint/$movieId';
  static String checkBookmarkUrl(String movieId) =>
      '$baseUrl$bookmarkEndpoint/check/$movieId';

  static const String savedMovieEndpoint = '/api/saved-movies';
  static String get getSavedMoviesUrl => '$baseUrl$savedMovieEndpoint';
  static String get saveMovieUrl => '$baseUrl$savedMovieEndpoint';
  static String removeSavedMovieUrl(String movieId) =>
      '$baseUrl$savedMovieEndpoint/$movieId';

  static const String watchRoomEndpoint = '/api/watch-rooms';
  static String get getWatchRoomsUrl => '$baseUrl$watchRoomEndpoint';
  static String get createWatchRoomUrl => '$baseUrl$watchRoomEndpoint';
  static String getWatchRoomUrl(String code) =>
      '$baseUrl$watchRoomEndpoint/$code';
  static String joinWatchRoomUrl(String code) =>
      '$baseUrl$watchRoomEndpoint/$code/join';
  static String leaveWatchRoomUrl(String code) =>
      '$baseUrl$watchRoomEndpoint/$code/leave';
  static String closeWatchRoomUrl(String code) =>
      '$baseUrl$watchRoomEndpoint/$code';

  // AWS API Gateway WebSocket API (realtime watch room sync)
  static const String socketUrl =
      'wss://n5hhh58ty7.execute-api.ap-southeast-1.amazonaws.com/prod';

  static const Duration timeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}