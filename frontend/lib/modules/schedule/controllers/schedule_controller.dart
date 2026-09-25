import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/schedule_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';

class ScheduleController extends GetxController {
  final ScheduleService _scheduleService = ScheduleService();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final allSchedules = <ScheduleModel>[].obs;
  final selectedDay = 'Semua'.obs;

  final days = ['Semua', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  final scheduleDays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  final isAdmin = false.obs;
  final guruList = <UserModel>[].obs;
  final classList = <ClassModel>[].obs;
  final subjectList = <SubjectModel>[].obs;
  final selectedFilterGuru = Rxn<int>();

  int? get currentUserId => AuthService().currentUser?.id;
  bool canModifySchedule(ScheduleModel schedule) => isAdmin.value || (schedule.guruId == currentUserId);

  // Form State
  final editingSchedule = Rxn<ScheduleModel>();
  final selectedHari = 'Senin'.obs;
  final selectedKelasId = Rxn<int>();
  final selectedMapelId = Rxn<int>();
  final selectedGuruId = Rxn<int>();
  final jamMulaiController = TextEditingController();
  final jamSelesaiController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    loadDependencies();
    loadSchedules();
  }

  @override
  void onClose() {
    jamMulaiController.dispose();
    jamSelesaiController.dispose();
    super.onClose();
  }

  Future<void> loadDependencies() async {
    try {
      final classes = await _scheduleService.getClasses();
      classList.assignAll(classes);

      final subjects = await _scheduleService.getSubjects();
      subjectList.assignAll(subjects);

      final teachers = await _scheduleService.getGuruList();
      guruList.assignAll(teachers);
    } catch (_) {}
  }

  Future<void> loadSchedules() async {
    isLoading.value = true;
    try {
      if (isAdmin.value && guruList.isEmpty) {
        final teachers = await _scheduleService.getGuruList();
        guruList.assignAll(teachers);
      }

      final list = await _scheduleService.getAllSchedules(guruId: selectedFilterGuru.value);
      allSchedules.assignAll(list);
    } catch (_) {
      // fallback
    } finally {
      isLoading.value = false;
    }
  }

  void filterByDay(String day) {
    selectedDay.value = day;
  }

  void filterByGuru(int? guruId) {
    selectedFilterGuru.value = guruId;
    loadSchedules();
  }

  List<ScheduleModel> get filteredSchedules {
    if (selectedDay.value == 'Semua') {
      return allSchedules;
    }
    return allSchedules.where((s) => s.hari == selectedDay.value).toList();
  }

  void initCreateForm() {
    editingSchedule.value = null;
    selectedHari.value = (selectedDay.value != 'Semua' && scheduleDays.contains(selectedDay.value))
        ? selectedDay.value
        : 'Senin';
    selectedKelasId.value = classList.isNotEmpty ? classList.first.id : null;
    selectedMapelId.value = subjectList.isNotEmpty ? subjectList.first.id : null;

    final user = AuthService().currentUser;
    if (isAdmin.value) {
      selectedGuruId.value = guruList.isNotEmpty ? guruList.first.id : (user?.id ?? 1);
    } else {
      selectedGuruId.value = user?.id ?? 1;
    }

    jamMulaiController.text = '07:30';
    jamSelesaiController.text = '09:00';
  }

  bool initEditForm(ScheduleModel schedule) {
    if (!canModifySchedule(schedule)) {
      AlertHelper.showError('Anda hanya dapat mengubah jadwal mengajar milik Anda sendiri');
      return false;
    }

    editingSchedule.value = schedule;
    selectedHari.value = schedule.hari;
    selectedKelasId.value = schedule.kelasId;
    selectedMapelId.value = schedule.mapelId;
    selectedGuruId.value = schedule.guruId;
    jamMulaiController.text = schedule.jamMulai;
    jamSelesaiController.text = schedule.jamSelesai;
    return true;
  }

  Future<void> pickTime(BuildContext context, bool isStart) async {
    final currentText = isStart ? jamMulaiController.text : jamSelesaiController.text;
    int hour = isStart ? 7 : 9;
    int minute = isStart ? 30 : 0;
    if (currentText.contains(':')) {
      final parts = currentText.split(':');
      hour = int.tryParse(parts[0]) ?? hour;
      minute = int.tryParse(parts[1]) ?? minute;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        jamMulaiController.text = formatted;
      } else {
        jamSelesaiController.text = formatted;
      }
    }
  }

  Future<void> saveSchedule() async {
    if (selectedKelasId.value == null) {
      AlertHelper.showWarning('Silakan pilih kelas terlebih dahulu');
      return;
    }
    if (selectedMapelId.value == null) {
      AlertHelper.showWarning('Silakan pilih mata pelajaran terlebih dahulu');
      return;
    }
    if (jamMulaiController.text.trim().isEmpty || jamSelesaiController.text.trim().isEmpty) {
      AlertHelper.showWarning('Silakan masukkan jam mulai dan jam selesai');
      return;
    }

    if (!isAdmin.value) {
      selectedGuruId.value = currentUserId;
      if (editingSchedule.value != null && !canModifySchedule(editingSchedule.value!)) {
        AlertHelper.showError('Anda tidak memiliki izin mengubah jadwal guru lain');
        return;
      }
    }

    isSaving.value = true;
    try {
      final kId = selectedKelasId.value!;
      final mId = selectedMapelId.value!;
      final hari = selectedHari.value;
      final jMulai = jamMulaiController.text.trim();
      final jSelesai = jamSelesaiController.text.trim();

      // Find names for fallback display
      final namaK = classList.firstWhereOrNull((c) => c.id == kId)?.namaKelas;
      final namaM = subjectList.firstWhereOrNull((s) => s.id == mId)?.namaMapel;
      final gId = isAdmin.value ? (selectedGuruId.value ?? currentUserId ?? 1) : (currentUserId ?? 1);
      final namaG = guruList.firstWhereOrNull((g) => g.id == gId)?.nama ?? AuthService().currentUser?.nama;

      if (editingSchedule.value == null) {
        // Create
        final result = await _scheduleService.createSchedule(
          kelasId: kId,
          mapelId: mId,
          hari: hari,
          jamMulai: jMulai,
          jamSelesai: jSelesai,
          guruId: gId,
          namaKelas: namaK,
          namaMapel: namaM,
          namaGuru: namaG,
        );

        if (result != null) {
          Get.back(); // close modal
          AlertHelper.showSuccess('Jadwal baru berhasil ditambahkan');
          await loadSchedules();
        } else {
          AlertHelper.showError('Gagal menambahkan jadwal');
        }
      } else {
        // Update
        final id = editingSchedule.value!.id;
        final result = await _scheduleService.updateSchedule(
          id,
          kelasId: kId,
          mapelId: mId,
          hari: hari,
          jamMulai: jMulai,
          jamSelesai: jSelesai,
          guruId: gId,
          namaKelas: namaK,
          namaMapel: namaM,
          namaGuru: namaG,
        );

        if (result != null) {
          Get.back(); // close modal
          AlertHelper.showSuccess('Jadwal berhasil diperbarui');
          await loadSchedules();
        } else {
          AlertHelper.showError('Gagal memperbarui jadwal');
        }
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan saat menyimpan jadwal: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmDelete(ScheduleModel schedule) async {
    if (!canModifySchedule(schedule)) {
      AlertHelper.showError('Anda hanya dapat menghapus jadwal mengajar milik Anda sendiri');
      return;
    }

    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Hapus Jadwal',
      message: 'Apakah Anda yakin ingin menghapus jadwal ${schedule.namaMapel ?? "ini"} untuk kelas ${schedule.namaKelas ?? ""} pada hari ${schedule.hari}?',
      confirmText: 'Hapus Jadwal',
      isDanger: true,
    );

    if (confirmed) {
      final success = await _scheduleService.deleteSchedule(schedule.id);
      if (success) {
        AlertHelper.showSuccess('Jadwal berhasil dihapus');
        await loadSchedules();
      } else {
        AlertHelper.showError('Gagal menghapus jadwal');
      }
    }
  }
}
