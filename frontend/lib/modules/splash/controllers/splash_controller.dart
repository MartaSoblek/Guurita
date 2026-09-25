import 'package:get/get.dart';
import '../../../data/services/auth_service.dart';

class SplashController extends GetxController {
  final AuthService _authService = AuthService();
  bool _hasNavigated = false;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  @override
  void onReady() {
    super.onReady();
    if (!_hasNavigated) {
      _startTimer();
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      navigateToNextScreen();
    });
  }

  void navigateToNextScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    try {
      if (_authService.isAuthenticated) {
        Get.offAllNamed('/main');
      } else {
        Get.offAllNamed('/login');
      }
    } catch (_) {
      Get.offAllNamed('/login');
    }
  }
}
