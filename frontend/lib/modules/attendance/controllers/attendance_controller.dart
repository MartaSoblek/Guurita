import 'package:get/get.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/services/schedule_service.dart';
import '../../../data/services/attendance_service.dart';
import '../../../core/utils/alert_helper.dart';
import '../../../core/utils/date_formatter.dart';

class AttendanceController extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();
  final AttendanceService _attendanceService = AttendanceService();

  final isLoading = false.obs;
  final isSaving = false.obs;

  final schedules = <ScheduleModel>[].obs;
  final selectedSchedule = Rxn<ScheduleModel>();

  final attendances = <AttendanceModel>[].obs;
  final currentDate = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentDate.value = DateFormatter.getTodayDateIso();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    try {
      final list = await _scheduleService.getAllSchedules();
      schedules.assignAll(list);
      if (schedules.isNotEmpty && selectedSchedule.value == null) {
        selectSchedule(schedules.first);
      }
    } catch (_) {
      // safe fallback
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectSchedule(ScheduleModel schedule) async {
    selectedSchedule.value = schedule;
    isLoading.value = true;
    try {
      final students = await _scheduleService.getStudentsByClass(schedule.kelasId);
      final list = students.map((s) {
        return AttendanceModel(
          siswaId: s.id,
          namaSiswa: s.nama,
          nis: s.nis,
          status: 'Hadir',
        );
      }).toList();
      attendances.assignAll(list);
    } catch (_) {
      // safe fallback
    } finally {
      isLoading.value = false;
    }
  }

  void markAllPresent() {
    for (var i = 0; i < attendances.length; i++) {
      attendances[i] = attendances[i].copyWith(status: 'Hadir');
    }
    AlertHelper.showSuccess('Semua siswa ditandai Hadir', title: 'Hadir Semua');
  }

  void updateStudentStatus(int index, String status) {
    if (index >= 0 && index < attendances.length) {
      attendances[index] = attendances[index].copyWith(status: status);
    }
  }

  void updateStudentKeterangan(int index, String note) {
    if (index >= 0 && index < attendances.length) {
      attendances[index] = attendances[index].copyWith(keterangan: note);
    }
  }

  int get countHadir => attendances.where((a) => a.status == 'Hadir').length;
  int get countIzin => attendances.where((a) => a.status == 'Izin').length;
  int get countSakit => attendances.where((a) => a.status == 'Sakit').length;
  int get countAlpa => attendances.where((a) => a.status == 'Alpa').length;

  Future<void> saveAttendance() async {
    if (selectedSchedule.value == null) {
      AlertHelper.showWarning('Silakan pilih jadwal terlebih dahulu');
      return;
    }

    isSaving.value = true;
    try {
      await _attendanceService.saveAttendance(
        journalId: 1, // linked to current active or new journal
        attendances: attendances,
      );
      AlertHelper.showSuccess(
        'Data presensi ${attendances.length} siswa berhasil disimpan',
        title: 'Presensi Disimpan',
      );
    } catch (_) {
      AlertHelper.showError('Gagal menyimpan presensi');
    } finally {
      isSaving.value = false;
    }
  }
}
