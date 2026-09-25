import 'package:get/get.dart';
import 'app_routes.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/main_navigation/views/main_navigation_view.dart';
import '../../modules/main_navigation/bindings/navigation_binding.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.main,
      page: () => const MainNavigationView(),
      binding: NavigationBinding(),
    ),
  ];
}
