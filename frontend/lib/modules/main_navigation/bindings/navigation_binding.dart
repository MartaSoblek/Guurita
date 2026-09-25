import 'package:get/get.dart';
import '../controllers/navigation_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../schedule/controllers/schedule_controller.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../journal/controllers/journal_controller.dart';
import '../../report/controllers/report_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(() => NavigationController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<ScheduleController>(() => ScheduleController());
    Get.lazyPut<AttendanceController>(() => AttendanceController());
    Get.lazyPut<JournalController>(() => JournalController());
    Get.lazyPut<ReportController>(() => ReportController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
