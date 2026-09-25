import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/export_helper.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/class_service.dart';
import '../../../data/services/report_service.dart';
import '../../../data/services/schedule_service.dart';
import '../../../data/services/subject_service.dart';

class ReportController extends GetxController {
  final ReportService _reportService = ReportService();
  final ScheduleService _scheduleService = ScheduleService();
  final ClassService _classService = ClassService();
  final SubjectService _subjectService = SubjectService();

  final isLoading = true.obs;
  final isExporting = false.obs;

  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;
  final selectedClass = Rxn<int>();
  final selectedSubject = Rxn<int>();
  final selectedGuru = Rxn<int>();

  final searchQuery = ''.obs;
  final sortBy = 'Nama A-Z'.obs;

  final isAdmin = false.obs;
  final classList = <ClassModel>[].obs;
  final subjectList = <SubjectModel>[].obs;
  final guruList = <UserModel>[].obs;

  final totalPertemuan = 0.obs;
  final totalSiswa = 0.obs;
  final totalHadir = 0.obs;
  final totalIzin = 0.obs;
  final totalSakit = 0.obs;
  final totalAlpa = 0.obs;
  final persentaseHadir = 0.0.obs;

  final namaKelas = 'Semua Kelas'.obs;
  final namaMapel = 'Semua Mapel'.obs;
  final namaGuru = 'Semua Guru'.obs;

  final pertemuanList = <Map<String, dynamic>>[].obs;
  final studentRecaps = <Map<String, dynamic>>[].obs;

  final months = const [
    {'val': 1, 'name': 'Januari'},
    {'val': 2, 'name': 'Februari'},
    {'val': 3, 'name': 'Maret'},
    {'val': 4, 'name': 'April'},
    {'val': 5, 'name': 'Mei'},
    {'val': 6, 'name': 'Juni'},
    {'val': 7, 'name': 'Juli'},
    {'val': 8, 'name': 'Agustus'},
    {'val': 9, 'name': 'September'},
    {'val': 10, 'name': 'Oktober'},
    {'val': 11, 'name': 'November'},
    {'val': 12, 'name': 'Desember'},
  ];

  final years = [2024, 2025, 2026, 2027];

  final sortOptions = const [
    'Nama A-Z',
    'Nama Z-A',
    '% Tertinggi',
    '% Terendah',
    'Alpa Terbanyak',
  ];

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    _initData();
  }

  Future<void> _initData() async {
    await loadFilterOptions();
    await loadReport();
  }

  Future<void> loadFilterOptions() async {
    try {
      final classes = await _classService.getClasses();
      classList.assignAll(classes);
      if (selectedClass.value == null && classList.isNotEmpty) {
        selectedClass.value = classList.first.id;
      }

      final subjects = await _subjectService.getSubjects();
      subjectList.assignAll(subjects);

      if (isAdmin.value) {
        final teachers = await _scheduleService.getGuruList();
        guruList.assignAll(teachers);
      }
    } catch (_) {
      // Safe fallback
    }
  }

  Future<void> loadReport() async {
    isLoading.value = true;
    try {
      final summary = await _reportService.getAttendanceReport(
        bulan: selectedMonth.value,
        tahun: selectedYear.value,
        kelasId: selectedClass.value,
        mapelId: selectedSubject.value,
        guruId: selectedGuru.value,
      );

      namaKelas.value = summary.namaKelas;
      namaMapel.value = summary.namaMapel;
      namaGuru.value = summary.namaGuru;
      totalPertemuan.value = summary.totalPertemuan;
      totalSiswa.value = summary.totalSiswa;
      totalHadir.value = summary.totalHadir;
      totalIzin.value = summary.totalIzin;
      totalSakit.value = summary.totalSakit;
      totalAlpa.value = summary.totalAlpa;
      persentaseHadir.value = summary.persentaseKehadiran;
      pertemuanList.assignAll(summary.pertemuanList);
      studentRecaps.assignAll(summary.perSiswa);
    } catch (_) {
      // safe fallback
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredStudents {
    final query = searchQuery.value.trim().toLowerCase();
    var list = studentRecaps.where((s) {
      if (query.isEmpty) return true;
      final name = (s['nama'] ?? '').toString().toLowerCase();
      final nis = (s['nis'] ?? '').toString().toLowerCase();
      return name.contains(query) || nis.contains(query);
    }).toList();

    switch (sortBy.value) {
      case 'Nama Z-A':
        list.sort((a, b) => (b['nama'] ?? '').toString().compareTo((a['nama'] ?? '').toString()));
        break;
      case '% Tertinggi':
        list.sort((a, b) => ((b['persen'] ?? 0) as num).compareTo((a['persen'] ?? 0) as num));
        break;
      case '% Terendah':
        list.sort((a, b) => ((a['persen'] ?? 0) as num).compareTo((b['persen'] ?? 0) as num));
        break;
      case 'Alpa Terbanyak':
        list.sort((a, b) => ((b['alpa'] ?? 0) as num).compareTo((a['alpa'] ?? 0) as num));
        break;
      case 'Nama A-Z':
      default:
        list.sort((a, b) => (a['nama'] ?? '').toString().compareTo((b['nama'] ?? '').toString()));
        break;
    }

    return list;
  }

  String get selectedMonthName {
    final m = months.firstWhere((element) => element['val'] == selectedMonth.value, orElse: () => months[0]);
    return m['name'] as String;
  }

  void filterByGuru(int? val) {
    selectedGuru.value = val;
    loadReport();
  }

  void filterByClass(int? val) {
    selectedClass.value = val;
    loadReport();
  }

  void filterBySubject(int? val) {
    selectedSubject.value = val;
    loadReport();
  }

  void filterByMonth(int? val) {
    if (val != null) {
      selectedMonth.value = val;
      loadReport();
    }
  }

  void filterByYear(int? val) {
    if (val != null) {
      selectedYear.value = val;
      loadReport();
    }
  }

  String generateCsvString() {
    final buffer = StringBuffer();
    buffer.writeln('LAPORAN REKAPITULASI KEHADIRAN SISWA');
    buffer.writeln('SMK NEGERI 1 ABANG');
    buffer.writeln('Kelas:,"${namaKelas.value}"');
    buffer.writeln('Mata Pelajaran:,"${namaMapel.value}"');
    buffer.writeln('Guru Pengampu:,"${namaGuru.value}"');
    buffer.writeln('Periode:,"$selectedMonthName ${selectedYear.value}"');
    buffer.writeln('Total Pertemuan:,"${totalPertemuan.value}"');
    buffer.writeln('Rata-rata Kehadiran:,"${persentaseHadir.value}%"');
    buffer.writeln();
    buffer.writeln('"NO","NIS","NAMA SISWA","HADIR","IZIN","SAKIT","ALPA","TOTAL PERTEMUAN","PERSENTASE","STATUS"');

    final list = filteredStudents;
    for (int i = 0; i < list.length; i++) {
      final s = list[i];
      final no = i + 1;
      final nis = s['nis'] ?? '-';
      final nama = (s['nama'] ?? '').toString().replaceAll('"', '""');
      final hadir = s['hadir'] ?? 0;
      final izin = s['izin'] ?? 0;
      final sakit = s['sakit'] ?? 0;
      final alpa = s['alpa'] ?? 0;
      final total = totalPertemuan.value > 0 ? totalPertemuan.value : (s['total_tercatat'] ?? 0);
      final persen = s['persen'] ?? 0.0;
      final status = s['evaluasi'] ?? 'Baik';

      buffer.writeln('$no,"$nis","$nama",$hadir,$izin,$sakit,$alpa,$total,$persen%,"$status"');
    }

    return buffer.toString();
  }

  void exportCsv() {
    try {
      final csvContent = generateCsvString();
      final cleanClassName = namaKelas.value.replaceAll(' ', '_');
      final fileName = 'Rekap_Presensi_${cleanClassName}_${selectedMonthName}_${selectedYear.value}.csv';
      ExportHelper.downloadCsv(fileName, csvContent);

      Get.snackbar(
        'Ekspor Berhasil',
        'Data rekapitulasi $fileName berhasil diunduh.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Ekspor Gagal',
        'Terjadi kendala saat mengunduh CSV: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void copyCsvToClipboard() {
    final csvContent = generateCsvString();
    Clipboard.setData(ClipboardData(text: csvContent));
    Get.snackbar(
      'Tersalin',
      'Data CSV berhasil disalin ke papan klip.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void printReport() {
    ExportHelper.triggerPrint();
  }
}
