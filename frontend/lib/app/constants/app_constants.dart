class AppConstants {
  static const String appName = 'GURITA';
  static const String appSubtitle = 'Gerbang Utama Informasi Sekolah';
  static const String schoolName = '';
  static const String appFullTitle = 'GURITA — Gerbang Utama Informasi Sekolah';

  // Storage keys
  static const String tokenKey = 'gurita_auth_token';
  static const String userKey = 'gurita_user_profile';
  static const String rememberKey = 'gurita_remember_me';

  // API Config
  // Default to localhost:8000 for web/desktop, 10.0.2.2 for Android emulator
  static const String apiDevBaseUrl = 'http://localhost:8000/api';
  static const String apiAndroidEmulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String apiProdBaseUrl = 'https://domain-sekolah.sch.id/api';

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double maxContentWidth = 1200.0;
}
