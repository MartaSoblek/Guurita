import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../views/camera_capture_dialog.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/models/journal_session_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/services/journal_service.dart';
import '../../../core/utils/alert_helper.dart';
import '../../../core/utils/date_formatter.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/schedule_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class JournalController extends GetxController {
  final JournalService _journalService = JournalService();
  final ScheduleService _scheduleService = ScheduleService();

  final isLoading = false.obs;
  final isSaving = false.obs;

  // Photo Documentation State
  final selectedPhotoBytes = Rxn<Uint8List>();
  final selectedPhotoName = Rxn<String>();
  final existingPhotoUrl = Rxn<String>();
  final isPhotoDeleted = false.obs;

  // Semester Sessions State (Halaman awal isi jurnal 1 semester)
  final semesterSessions = <JournalSessionModel>[].obs;
  final isLoadingSessions = false.obs;
  final semesterTitle = 'Semester Berjalan'.obs;
  final totalSesiSemester = 0.obs;
  final totalSudahDiisi = 0.obs;
  final totalBelumDiisi = 0.obs;
  final totalHariIni = 0.obs;
  final selectedStatusFilter = 'semua'.obs;
  final sessionSearchQuery = ''.obs;
  final isFormOpen = false.obs;
  final selectedSession = Rxn<JournalSessionModel>();

  // Form Controllers
  final formKey = GlobalKey<FormState>();
  final tanggalController = TextEditingController();
  final kelasController = TextEditingController();
  final mapelController = TextEditingController();
  final jamController = TextEditingController();
  final materiController = TextEditingController();
  final kegiatanController = TextEditingController();
  final metodeController = TextEditingController();
  final mediaController = TextEditingController();
  final kendalaController = TextEditingController();
  final tindakLanjutController = TextEditingController();
  final catatanController = TextEditingController();

  final selectedSchedule = Rxn<ScheduleModel>();
  final currentAttendance = <AttendanceModel>[].obs;
  final isLoadingStudents = false.obs;

  int get countHadir => currentAttendance.where((a) => a.status == 'Hadir').length;
  int get countIzin => currentAttendance.where((a) => a.status == 'Izin').length;
  int get countSakit => currentAttendance.where((a) => a.status == 'Sakit').length;
  int get countAlpa => currentAttendance.where((a) => a.status == 'Alpa').length;
  int get totalSiswa => currentAttendance.length;

  void markAllPresent() {
    if (currentAttendance.isEmpty) {
      AlertHelper.showWarning('Belum ada data presensi siswa untuk kelas ini.');
      return;
    }
    for (var i = 0; i < currentAttendance.length; i++) {
      currentAttendance[i] = currentAttendance[i].copyWith(status: 'Hadir');
    }
    AlertHelper.showSuccess('Semua siswa (${currentAttendance.length} siswa) ditandai Hadir', title: 'Hadir Semua');
  }

  void updateAttendanceStatus(int index, String status) {
    if (index >= 0 && index < currentAttendance.length) {
      currentAttendance[index] = currentAttendance[index].copyWith(status: status);
    }
  }

  void updateAttendanceKeterangan(int index, String note) {
    if (index >= 0 && index < currentAttendance.length) {
      currentAttendance[index] = currentAttendance[index].copyWith(keterangan: note);
    }
  }

  Future<void> pickPhotoFromFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();

        if (bytes.length > 10 * 1024 * 1024) {
          AlertHelper.showWarning('Ukuran foto terlalu besar. Maksimal 10MB.');
          return;
        }
        selectedPhotoBytes.value = Uint8List.fromList(bytes);
        selectedPhotoName.value = file.name;
        isPhotoDeleted.value = false;
      }
    } catch (e) {
      AlertHelper.showError('Gagal memilih foto kegiatan: $e');
    }
  }

  // Alias untuk kompatibilitas
  Future<void> pickPhoto() => pickPhotoFromFile();

  /// Mengambil foto langsung: jika HP maka buka kamera HP native,
  /// jika Laptop/Desktop maka buka dialog webcam live feed.
  Future<void> pickPhotoFromCamera(BuildContext context) async {
    try {
      final isMobile = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

      if (isMobile) {
        final picker = ImagePicker();
        final photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (photo != null) {
          final bytes = await photo.readAsBytes();
          if (bytes.length > 10 * 1024 * 1024) {
            AlertHelper.showWarning('Ukuran foto terlalu besar. Maksimal 10MB.');
            return;
          }
          selectedPhotoBytes.value = Uint8List.fromList(bytes);
          selectedPhotoName.value =
              'kegiatan_kamera_${DateTime.now().millisecondsSinceEpoch}.jpg';
          isPhotoDeleted.value = false;
        }
      } else {
        // Laptop / Komputer Desktop: Buka modal webcam live feed
        final bytes = await CameraCaptureDialog.show(context);
        if (bytes != null) {
          if (bytes.length > 10 * 1024 * 1024) {
            AlertHelper.showWarning('Ukuran foto terlalu besar. Maksimal 10MB.');
            return;
          }
          selectedPhotoBytes.value = bytes;
          selectedPhotoName.value =
              'kegiatan_webcam_${DateTime.now().millisecondsSinceEpoch}.jpg';
          isPhotoDeleted.value = false;
        }
      }
    } catch (e) {
      AlertHelper.showError('Gagal mengambil foto dari kamera/webcam: $e');
    }
  }

  /// Menampilkan pilihan sumber foto (Kamera/Webcam atau File)
  void showPhotoSourceSelection(BuildContext context) {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Sumber Foto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                leading: Icon(
                  isMobile ? Icons.camera_alt_rounded : Icons.videocam_rounded,
                  color: const Color(0xFF2563EB),
                  size: 22,
                ),
                title: Text(
                  isMobile ? 'Kamera HP' : 'Webcam Laptop',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                onTap: () {
                  Navigator.of(ctx).pop();
                  pickPhotoFromCamera(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                title: const Text(
                  'Galeri / File',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                onTap: () {
                  Navigator.of(ctx).pop();
                  pickPhotoFromFile();
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  void removePhoto() {
    selectedPhotoBytes.value = null;
    selectedPhotoName.value = null;
    if (existingPhotoUrl.value != null) {
      isPhotoDeleted.value = true;
    }
    existingPhotoUrl.value = null;
  }

  // History & Filter
  final historyJournals = <JournalModel>[].obs;
  final searchQuery = ''.obs;
  final selectedFilterClass = Rxn<int>();
  final selectedFilterDate = ''.obs;

  final isAdmin = false.obs;
  final guruList = <UserModel>[].obs;
  final classList = <ClassModel>[].obs;
  final selectedFilterGuru = Rxn<int>();

  final selectedDetailJournal = Rxn<JournalModel>();

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    tanggalController.text = DateFormatter.getTodayDateIso();
    loadSemesterSessions();
    loadJournalHistory();
  }

  void populateFromSchedule(ScheduleModel schedule) {
    selectedSchedule.value = schedule;
    kelasController.text = schedule.namaKelas ?? '';
    mapelController.text = schedule.namaMapel ?? '';
    jamController.text = '${schedule.jamMulai} - ${schedule.jamSelesai}';
    tanggalController.text = DateFormatter.getTodayDateIso();
  }

  void setAttendanceFromCurrent(List<AttendanceModel> list) {
    currentAttendance.assignAll(list);
  }

  Future<void> loadSemesterSessions() async {
    isLoadingSessions.value = true;
    try {
      if (isAdmin.value && guruList.isEmpty) {
        final teachers = await _scheduleService.getGuruList();
        guruList.assignAll(teachers);
      }

      final res = await _journalService.getSemesterSessions(
        guruId: selectedFilterGuru.value,
        kelasId: selectedFilterClass.value,
        status: selectedStatusFilter.value == 'semua' ? null : selectedStatusFilter.value,
        search: sessionSearchQuery.value,
      );

      semesterTitle.value = res['semester'] ?? 'Semester Berjalan';
      totalSesiSemester.value = res['total_sesi'] ?? 0;
      totalSudahDiisi.value = res['total_sudah_diisi'] ?? 0;
      totalBelumDiisi.value = res['total_belum_diisi'] ?? 0;
      totalHariIni.value = res['total_hari_ini'] ?? 0;

      final List<JournalSessionModel> list = res['sessions'] ?? [];
      semesterSessions.assignAll(list);
    } catch (_) {
      // safe fallback
    } finally {
      isLoadingSessions.value = false;
    }
  }

  void filterStatus(String status) {
    selectedStatusFilter.value = status;
    loadSemesterSessions();
  }

  void searchSessions(String query) {
    sessionSearchQuery.value = query;
    loadSemesterSessions();
  }

  void selectSessionToFill(JournalSessionModel session) async {
    // Aturan Penting: Tanggal di waktu yang akan datang tidak dapat diisi
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (session.tanggal.compareTo(todayStr) > 0) {
      AlertHelper.showWarning('Tidak dapat mengisi jurnal di waktu yang akan datang.');
      return;
    }

    selectedSession.value = session;
    tanggalController.text = session.tanggal;
    kelasController.text = session.namaKelas;
    mapelController.text = session.namaMapel;
    jamController.text = '${session.jamMulai} - ${session.jamSelesai}';

    currentAttendance.clear();
    isLoadingStudents.value = true;
    isFormOpen.value = true;
    selectedPhotoBytes.value = null;
    selectedPhotoName.value = null;
    existingPhotoUrl.value = null;
    isPhotoDeleted.value = false;

    try {
      // Jika sudah diisi sebelumnya, muat datanya untuk dilihat atau diedit
      if (session.isSudahDiisi && session.jurnalId != null) {
        final existing = await _journalService.getJournalById(session.jurnalId!);
        if (existing != null) {
          materiController.text = existing.materi;
          kegiatanController.text = existing.kegiatan;
          metodeController.text = existing.metode ?? '';
          mediaController.text = existing.media ?? '';
          kendalaController.text = existing.kendala ?? '';
          tindakLanjutController.text = existing.tindakLanjut ?? '';
          catatanController.text = existing.catatan ?? '';
          existingPhotoUrl.value = existing.fotoKegiatanUrl ?? existing.fotoKegiatan;
          if (existing.kehadiran != null && existing.kehadiran!.isNotEmpty) {
            currentAttendance.assignAll(existing.kehadiran!);
          } else {
            final students = await _scheduleService.getStudentsByClass(session.kelasId);
            final list = students.map((s) => AttendanceModel(
              siswaId: s.id,
              namaSiswa: s.nama,
              nis: s.nis,
              status: 'Hadir',
            )).toList();
            currentAttendance.assignAll(list);
          }
        } else {
          _clearForm();
        }
      } else {
        _clearForm();
        // Muat daftar siswa kelas untuk presensi baru
        final students = await _scheduleService.getStudentsByClass(session.kelasId);
        final list = students.map((s) => AttendanceModel(
          siswaId: s.id,
          namaSiswa: s.nama,
          nis: s.nis,
          status: 'Hadir',
        )).toList();
        currentAttendance.assignAll(list);
      }
    } catch (_) {
      // safe fallback
    } finally {
      isLoadingStudents.value = false;
    }
  }

  void closeForm() {
    isFormOpen.value = false;
    selectedSession.value = null;
    _clearForm();
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  Future<void> loadJournalHistory() async {
    isLoading.value = true;
    try {
      if (isAdmin.value && guruList.isEmpty) {
        final teachers = await _scheduleService.getGuruList();
        guruList.assignAll(teachers);
      }

      if (classList.isEmpty) {
        final classes = await _scheduleService.getClasses();
        classList.assignAll(classes);
      }

      final list = await _journalService.getJournals(
        search: searchQuery.value,
        tanggal: selectedFilterDate.value.isNotEmpty ? selectedFilterDate.value : null,
        kelasId: selectedFilterClass.value,
        guruId: selectedFilterGuru.value,
      );
      historyJournals.assignAll(list);
    } catch (_) {
      // safe fallback
    } finally {
      isLoading.value = false;
    }
  }

  void searchJournals(String query) {
    searchQuery.value = query;
    loadJournalHistory();
  }

  void filterByGuru(int? guruId) {
    selectedFilterGuru.value = guruId;
    loadSemesterSessions();
    loadJournalHistory();
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedFilterClass.value = null;
    selectedFilterDate.value = '';
    selectedFilterGuru.value = null;
    sessionSearchQuery.value = '';
    selectedStatusFilter.value = 'semua';
    loadSemesterSessions();
    loadJournalHistory();
  }

  Future<bool> saveJournal() async {
    if (!formKey.currentState!.validate()) return false;

    // Proteksi: Tidak dapat mengisi jurnal di waktu yang akan datang
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (tanggalController.text.trim().compareTo(todayStr) > 0) {
      AlertHelper.showWarning('Tidak dapat mengisi jurnal di waktu yang akan datang (tanggal tidak boleh melebihi hari ini).');
      return false;
    }

    isSaving.value = true;
    try {
      final isEdit = selectedSession.value?.isSudahDiisi == true && selectedSession.value?.jurnalId != null;

      if (isEdit) {
        final res = await _journalService.updateJournal(
          selectedSession.value!.jurnalId!,
          {
            'tanggal': tanggalController.text.trim(),
            'materi': materiController.text.trim(),
            'kegiatan': kegiatanController.text.trim().isNotEmpty ? kegiatanController.text.trim() : null,
            'metode': metodeController.text.trim().isNotEmpty ? metodeController.text.trim() : null,
            'media': mediaController.text.trim().isNotEmpty ? mediaController.text.trim() : null,
            'kendala': kendalaController.text.trim().isNotEmpty ? kendalaController.text.trim() : null,
            'tindak_lanjut': tindakLanjutController.text.trim().isNotEmpty ? tindakLanjutController.text.trim() : null,
            'catatan': catatanController.text.trim().isNotEmpty ? catatanController.text.trim() : null,
            'kehadiran': currentAttendance.map((a) => a.toJson()).toList(),
          },
          photoBytes: selectedPhotoBytes.value,
          photoName: selectedPhotoName.value,
          removePhoto: isPhotoDeleted.value,
        );

        if (res['success'] == true) {
          AlertHelper.showSuccess('Jurnal & presensi siswa tanggal ${tanggalController.text} berhasil diperbarui!');
          _clearForm();
          isFormOpen.value = false;
          selectedSession.value = null;
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
          await loadSemesterSessions();
          await loadJournalHistory();
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().loadDashboardData();
          }
          return true;
        } else {
          AlertHelper.showError(res['message'] ?? 'Gagal memperbarui jurnal');
          return false;
        }
      } else {
        final res = await _journalService.createJournal(
          jadwalId: selectedSession.value?.jadwalId ?? selectedSchedule.value?.id,
          tanggal: tanggalController.text.trim(),
          materi: materiController.text.trim(),
          kegiatan: kegiatanController.text.trim().isNotEmpty ? kegiatanController.text.trim() : null,
          metode: metodeController.text.trim().isNotEmpty ? metodeController.text.trim() : null,
          media: mediaController.text.trim().isNotEmpty ? mediaController.text.trim() : null,
          kendala: kendalaController.text.trim().isNotEmpty ? kendalaController.text.trim() : null,
          tindakLanjut: tindakLanjutController.text.trim().isNotEmpty ? tindakLanjutController.text.trim() : null,
          catatan: catatanController.text.trim().isNotEmpty ? catatanController.text.trim() : null,
          namaKelas: kelasController.text,
          namaMapel: mapelController.text,
          jamMulai: selectedSession.value?.jamMulai ?? selectedSchedule.value?.jamMulai,
          jamSelesai: selectedSession.value?.jamSelesai ?? selectedSchedule.value?.jamSelesai,
          attendanceList: currentAttendance.isNotEmpty ? currentAttendance.toList() : null,
          photoBytes: selectedPhotoBytes.value,
          photoName: selectedPhotoName.value,
        );

        if (res['success'] == true) {
          AlertHelper.showSuccess('Jurnal & presensi siswa tanggal ${tanggalController.text} berhasil disimpan!');
          _clearForm();
          isFormOpen.value = false;
          selectedSession.value = null;
          if (Get.isDialogOpen ?? false) {
            Get.back();
          }
          await loadSemesterSessions();
          await loadJournalHistory();
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().loadDashboardData();
          }
          return true;
        } else {
          AlertHelper.showError(res['message'] ?? 'Gagal menyimpan jurnal');
          return false;
        }
      }
    } catch (e) {
      AlertHelper.showError('Gagal menyimpan jurnal: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteJournal(int id) async {
    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Hapus Jurnal',
      message: 'Apakah Anda yakin ingin menghapus jurnal kegiatan mengajar ini?',
      confirmText: 'Hapus',
      isDanger: true,
    );

    if (confirmed) {
      final success = await _journalService.deleteJournal(id);
      if (success) {
        AlertHelper.showSuccess('Jurnal berhasil dihapus');
        loadJournalHistory();
      }
    }
  }

  void viewDetail(JournalModel journal) {
    selectedDetailJournal.value = journal;
  }

  void _clearForm() {
    materiController.clear();
    kegiatanController.clear();
    metodeController.clear();
    mediaController.clear();
    kendalaController.clear();
    tindakLanjutController.clear();
    catatanController.clear();
    currentAttendance.clear();
    selectedPhotoBytes.value = null;
    selectedPhotoName.value = null;
    existingPhotoUrl.value = null;
    isPhotoDeleted.value = false;
  }

  @override
  void onClose() {
    tanggalController.dispose();
    kelasController.dispose();
    mapelController.dispose();
    jamController.dispose();
    materiController.dispose();
    kegiatanController.dispose();
    metodeController.dispose();
    mediaController.dispose();
    kendalaController.dispose();
    tindakLanjutController.dispose();
    catatanController.dispose();
    super.onClose();
  }
}
