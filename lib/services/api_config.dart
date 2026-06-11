// Cấu hình API endpoints và hằng số hệ thống.
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.45:4000';

  // Backend phim serverless trên AWS (API Gateway + Lambda + DynamoDB).
  static const String awsBaseUrl =
      'https://c0ocqpmzj9.execute-api.ap-southeast-1.amazonaws.com/prod';

  static const String authEndpoint = '/api/auth';
  static const String userEndpoint = '/api/user';
  static const String commentEndpoint = '/api/comments';
  static const String movieEndpoint = '/api/movies';

  static String get registerUrl => '$awsBaseUrl$authEndpoint/register';
  static String get loginUrl => '$awsBaseUrl$authEndpoint/login';
  static String get verifyEmailUrl => '$awsBaseUrl$authEndpoint/verify-email';
  static String get googleLoginUrl => '$awsBaseUrl$authEndpoint/google-login';
  static String get resendVerifyOtpUrl =>
      '$awsBaseUrl$authEndpoint/resend-verify-otp';
  static String get forgotPasswordUrl =>
      '$awsBaseUrl$authEndpoint/forgot-password';
  static String get resetPasswordUrl => '$awsBaseUrl$authEndpoint/reset-password';

  static String updateUserUrl(String userId) =>
      '$awsBaseUrl$userEndpoint/$userId';

  static String getCommentsUrl(String movieId) =>
      '$awsBaseUrl$commentEndpoint/$movieId';
  static String get addCommentUrl => '$awsBaseUrl$commentEndpoint/add';

  static String getMoviesLimitUrl(int limit) =>
      '$awsBaseUrl$movieEndpoint/limit/$limit';
  static String getMoviesByCategoryUrl(String slug) =>
      '$awsBaseUrl$movieEndpoint/category/$slug';
  static String getMoviesByCountryUrl(String slug) =>
      '$awsBaseUrl$movieEndpoint/country/$slug';
  static String getMoviesByYearUrl(int year) =>
      '$awsBaseUrl$movieEndpoint/year/$year';

  // Các endpoints mới từ nhánh feature
  static String getMoviesByTypeUrl(String type) =>
      '$awsBaseUrl$movieEndpoint/type/$type';
  static String get hotMoviesUrl => '$awsBaseUrl$movieEndpoint/hot';
  static String get filterMoviesUrl => '$awsBaseUrl$movieEndpoint/filter';
  static String getMovieDetailUrl(String slug) =>
      '$awsBaseUrl$movieEndpoint/$slug';
  static String getMovieCastUrl(String slug) =>
      '$awsBaseUrl$movieEndpoint/$slug/cast';

  static String get searchMoviesUrl => '$awsBaseUrl$movieEndpoint';

  static const String bookmarkEndpoint = '/api/bookmarks';
  static String get getBookmarksUrl => '$awsBaseUrl$bookmarkEndpoint';
  static String get addBookmarkUrl => '$awsBaseUrl$bookmarkEndpoint';
  static String removeBookmarkUrl(String movieId) =>
      '$awsBaseUrl$bookmarkEndpoint/$movieId';
  static String checkBookmarkUrl(String movieId) =>
      '$awsBaseUrl$bookmarkEndpoint/check/$movieId';

  static const String savedMovieEndpoint = '/api/saved-movies';
  static String get getSavedMoviesUrl => '$awsBaseUrl$savedMovieEndpoint';
  static String get saveMovieUrl => '$awsBaseUrl$savedMovieEndpoint';
  static String removeSavedMovieUrl(String movieId) =>
      '$awsBaseUrl$savedMovieEndpoint/$movieId';

  static const String watchRoomEndpoint = '/api/watch-rooms';
  static String get getWatchRoomsUrl => '$awsBaseUrl$watchRoomEndpoint';
  static String get createWatchRoomUrl => '$awsBaseUrl$watchRoomEndpoint';
  static String getWatchRoomUrl(String code) =>
      '$awsBaseUrl$watchRoomEndpoint/$code';
  static String joinWatchRoomUrl(String code) =>
      '$awsBaseUrl$watchRoomEndpoint/$code/join';
  static String leaveWatchRoomUrl(String code) =>
      '$awsBaseUrl$watchRoomEndpoint/$code/leave';
  static String closeWatchRoomUrl(String code) =>
      '$awsBaseUrl$watchRoomEndpoint/$code';

  // AWS API Gateway WebSocket API (realtime watch room sync)
  static const String socketUrl =
      'wss://n5hhh58ty7.execute-api.ap-southeast-1.amazonaws.com/prod';

  static const Duration timeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}