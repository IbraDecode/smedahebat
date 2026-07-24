class AppConfig {
  AppConfig._();

  static const String appName = 'SMEDA HEBAT';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.smeda.hebat';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int splashDuration = 3;

  static const bool enableLogging = true;
  static const bool enableCrashReporting = true;
}
