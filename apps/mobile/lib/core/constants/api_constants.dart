class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:4000/api/v1';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String contentType = 'application/json';
  static const String accept = 'application/json';

  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';

  static const String locale = 'lang';
  static const String defaultLocale = 'id';

  static const int retryCount = 3;
}

class ApiEndpoints {
  ApiEndpoints._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String setPassword = '/auth/set-password';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String profile = '/auth/profile';
  static const String dashboard = '/dashboard';
  static const String schedule = '/academic/schedule';
  static const String attendance = '/attendance';
  static const String notifications = '/notifications';
}
