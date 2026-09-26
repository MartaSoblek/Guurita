import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/models/journal_session_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/schedule_service.dart';
import '../../../data/services/journal_service.dart';
import '../../../data/services/auth_service.dart';
import '../../journal/views/journal_form_dialog.dart';

class DashboardController extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();
  final JournalService _journalService = JournalService();

  final isLoading = true.obs;
  final todaySchedules = <ScheduleModel>[].obs;
  final todayJournals = <JournalModel>[].obs;
  final recentJournals = <JournalModel>[].obs;

  final totalKelasHariIni = 0.obs;
  final totalSiswaHadir = 0.obs;
  final totalJurnalHariIni = 0.obs;
  final persentaseKehadiran = '96.5%'.obs;

  final guruList = <UserModel>[].obs;
  final selectedFilterGuru = Rxn<int>();
  final isAdmin = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final user = AuthService().currentUser;
      isAdmin.value = user?.isAdmin ?? false;

      if (isAdmin.value && guruList.isEmpty) {
        final teachers = await _scheduleService.getGuruList();
        guruList.assignAll(teachers);
      }

      // Sesuai dengan masing-masing akun saja:
      // Jika non-admin, target selalu ID guru yang sedang login.
      // Jika admin, ikuti pilihan filter jika ada.
      final targetGuruId = isAdmin.value ? selectedFilterGuru.value : user?.id;

      final schedules = await _scheduleService.getTodaySchedules(guruId: targetGuruId);
      final journalsToday = await _journalService.getJournals(
        guruId: targetGuruId,
        tanggal: DateFormatter.getTodayDateIso(),
      );
      final journalsAll = await _journalService.getJournals(guruId: targetGuruId);

      todaySchedules.assignAll(schedules);
      todayJournals.assignAll(journalsToday);
      recentJournals.assignAll(journalsAll.take(5));

      totalKelasHariIni.value = schedules.length;
      totalJurnalHariIni.value = journalsToday.length;

      int hadir = 0;
      int totalPresensi = 0;
      for (final j in journalsToday) {
        hadir += j.totalHadir;
        totalPresensi += (j.totalHadir + j.totalIzin + j.totalSakit + j.totalAlpa);
      }
      totalSiswaHadir.value = hadir;

      if (totalPresensi > 0) {
        final pct = (hadir / totalPresensi) * 100;
        persentaseKehadiran.value = '${pct.toStringAsFixed(1)}%';
      } else if (schedules.isNotEmpty) {
        persentaseKehadiran.value = journalsToday.isNotEmpty ? '100%' : '0.0%';
      } else {
        persentaseKehadiran.value = '100%';
      }
    } catch (_) {
      // keep safe defaults
    } finally {
      isLoading.value = false;
    }
  }

  void filterByGuru(int? guruId) {
    selectedFilterGuru.value = guruId;
    loadDashboardData();
  }

  bool isJournalFilled(int jadwalId) {
    final todayStr = DateFormatter.getTodayDateIso();
    return todayJournals.any((j) => j.jadwalId == jadwalId && j.tanggal == todayStr) ||
        recentJournals.any((j) => j.jadwalId == jadwalId && j.tanggal == todayStr);
  }

  JournalSessionModel getSessionForSchedule(ScheduleModel schedule) {
    final todayStr = DateFormatter.getTodayDateIso();
    final existing = todayJournals.firstWhereOrNull(
          (j) => j.jadwalId == schedule.id && j.tanggal == todayStr,
        ) ??
        recentJournals.firstWhereOrNull(
          (j) => j.jadwalId == schedule.id && j.tanggal == todayStr,
        );

    return JournalSessionModel.fromSchedule(
      schedule,
      tanggal: todayStr,
      existingJournal: existing,
    );
  }

  Future<void> openJournalForm(BuildContext context, ScheduleModel schedule) async {
    final session = getSessionForSchedule(schedule);
    await JournalFormDialog.show(context, session);
    await loadDashboardData();
  }
}
