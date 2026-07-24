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
  static const String attendanceGenerate = '/attendance/generate';
  static const String attendanceScan = '/attendance/scan';
  static const String attendanceSession = '/attendance/session';
  static const String attendanceActiveSession = '/attendance/active-session';
  static const String attendanceByClass = '/attendance/class';
  static const String attendanceMy = '/attendance/my';
  static const String attendanceRecap = '/attendance/recap';
  static const String announcements = '/announcements';
  static const String notifications = '/notifications';
  static const String notificationsRead = '/notifications/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  static const String teacherSubjects = '/academic/teacher-subjects';
  static const String schedules = '/academic/schedules';
  static const String scheduleByClass = '/academic/schedules/by-class';
  static const String scheduleByTeacher = '/academic/schedules/by-teacher';
  static const String scheduleToday = '/academic/schedules/today';

  // Assignments
  static const String assignments = '/assignments';
  static const String submissions = '/submissions';
  static const String submissionsMy = '/submissions/my';

  // Grade & Rapor
  static const String gradeComponents = '/grade/components';
  static const String gradeScores = '/grade/scores';
  static const String gradeScoresBulk = '/grade/scores/bulk';
  static const String gradeScoresMy = '/grade/scores/my';
  static const String gradeRapor = '/grade/rapor';
  static const String gradeRaporGenerate = '/grade/rapor/generate';
  static const String gradeRaporMy = '/grade/rapor/my';
  static const String gradeRaporPublish = '/grade/rapor/publish';

  // Admin
  static const String users = '/users';
  static const String schoolProfile = '/school/profile';
  static const String academicYears = '/school/academic-years';
}
