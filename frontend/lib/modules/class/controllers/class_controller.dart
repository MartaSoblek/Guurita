import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import '../../../data/models/class_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/services/class_service.dart';
import '../../../data/services/student_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';

class ClassController extends GetxController {
  final ClassService _classService = ClassService();
  final StudentService _studentService = StudentService();

  // Class Management State
  final isLoading = true.obs;
  final isSaving = false.obs;
  final classes = <ClassModel>[].obs;
  final searchQuery = ''.obs;
  final selectedTingkatFilter = 'Semua'.obs;
  final isAdmin = false.obs;

  final editingClass = Rxn<ClassModel>();
  final namaKelasController = TextEditingController();
  final selectedTingkat = 'X'.obs;
  final List<String> tingkatOptions = ['X', 'XI', 'XII'];

  // Student Management State (when a class is clicked)
  final selectedClass = Rxn<ClassModel>();
  final isLoadingStudents = false.obs;
  final isSavingStudent = false.obs;
  final students = <StudentModel>[].obs;
  final studentSearchQuery = ''.obs;

  final editingStudent = Rxn<StudentModel>();
  final nisController = TextEditingController();
  final nisnController = TextEditingController();
  final namaSiswaController = TextEditingController();

  // Excel Import State
  final isImporting = false.obs;
  final isDownloadingTemplate = false.obs;
  final parsedImportStudents = <Map<String, String>>[].obs;
  final importError = ''.obs;
  final pasteController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    loadClasses();
  }

  @override
  void onClose() {
    namaKelasController.dispose();
    nisController.dispose();
    nisnController.dispose();
    namaSiswaController.dispose();
    pasteController.dispose();
    super.onClose();
  }

  // ==================== CLASS METHODS ====================

  Future<void> loadClasses() async {
    isLoading.value = true;
    try {
      final list = await _classService.getClasses();
      classes.assignAll(list);
    } catch (_) {
      // fallback
    } finally {
      isLoading.value = false;
    }
  }

  List<ClassModel> get filteredClasses {
    List<ClassModel> result = classes;

    if (selectedTingkatFilter.value != 'Semua') {
      result = result.where((c) => c.tingkat == selectedTingkatFilter.value).toList();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase().trim();
      result = result.where((c) {
        return c.namaKelas.toLowerCase().contains(q) || c.tingkat.toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }

  void openCreateDialog() {
    editingClass.value = null;
    namaKelasController.clear();
    selectedTingkat.value = 'X';
  }

  void openEditDialog(ClassModel cls) {
    editingClass.value = cls;
    namaKelasController.text = cls.namaKelas;
    if (tingkatOptions.contains(cls.tingkat)) {
      selectedTingkat.value = cls.tingkat;
    } else {
      selectedTingkat.value = 'X';
    }
  }

  Future<void> saveClass() async {
    final nama = namaKelasController.text.trim();
    final tingkat = selectedTingkat.value;

    if (nama.isEmpty) {
      AlertHelper.showWarning('Silakan masukkan nama kelas');
      return;
    }

    isSaving.value = true;
    try {
      if (editingClass.value == null) {
        // Create
        final result = await _classService.createClass(
          namaKelas: nama,
          tingkat: tingkat,
        );

        if (result != null) {
          Get.back(); // Close modal
          AlertHelper.showSuccess('Kelas "$nama" berhasil ditambahkan');
          await loadClasses();
        } else {
          AlertHelper.showError('Gagal menambahkan kelas');
        }
      } else {
        // Update
        final id = editingClass.value!.id;
        final result = await _classService.updateClass(
          id,
          namaKelas: nama,
          tingkat: tingkat,
        );

        if (result != null) {
          Get.back(); // Close modal
          AlertHelper.showSuccess('Kelas "$nama" berhasil diperbarui');
          await loadClasses();
        } else {
          AlertHelper.showError('Gagal memperbarui kelas');
        }
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmDelete(ClassModel cls) async {
    if (cls.totalSiswa > 0) {
      AlertHelper.showWarning(
        'Kelas "${cls.namaKelas}" tidak dapat dihapus karena masih memiliki ${cls.totalSiswa} siswa terdaftar.',
      );
      return;
    }

    if (cls.totalJadwal > 0) {
      AlertHelper.showWarning(
        'Kelas "${cls.namaKelas}" tidak dapat dihapus karena masih terdaftar pada ${cls.totalJadwal} jadwal mengajar.',
      );
      return;
    }

    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Hapus Data Kelas',
      message: 'Apakah Anda yakin ingin menghapus kelas "${cls.namaKelas}" tingkat ${cls.tingkat}?',
      confirmText: 'Hapus Kelas',
      isDanger: true,
    );

    if (confirmed) {
      final res = await _classService.deleteClass(cls.id);
      if (res['success'] == true) {
        AlertHelper.showSuccess(res['message'] ?? 'Data kelas berhasil dihapus');
        await loadClasses();
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal menghapus data kelas');
      }
    }
  }

  // ==================== STUDENT METHODS ====================

  void selectClass(ClassModel cls) {
    selectedClass.value = cls;
    studentSearchQuery.value = '';
    loadStudentsForSelectedClass();
  }

  void backToClassList() {
    selectedClass.value = null;
    studentSearchQuery.value = '';
    loadClasses(); // Refresh counts in class list
  }

  Future<void> loadStudentsForSelectedClass() async {
    if (selectedClass.value == null) return;

    isLoadingStudents.value = true;
    try {
      final list = await _studentService.getStudentsByClass(selectedClass.value!.id);
      students.assignAll(list);
    } catch (_) {
      // fallback
    } finally {
      isLoadingStudents.value = false;
    }
  }

  List<StudentModel> get filteredStudents {
    if (studentSearchQuery.value.trim().isEmpty) {
      return students;
    }
    final q = studentSearchQuery.value.toLowerCase().trim();
    return students.where((s) {
      return s.nama.toLowerCase().contains(q) ||
          s.nis.toLowerCase().contains(q) ||
          s.nisn.toLowerCase().contains(q);
    }).toList();
  }

  void openCreateStudentDialog() {
    editingStudent.value = null;
    nisController.clear();
    nisnController.clear();
    namaSiswaController.clear();
  }

  void openEditStudentDialog(StudentModel student) {
    editingStudent.value = student;
    nisController.text = student.nis;
    nisnController.text = student.nisn;
    namaSiswaController.text = student.nama;
  }

  Future<void> saveStudent() async {
    if (selectedClass.value == null) return;

    final nis = nisController.text.trim();
    final nisn = nisnController.text.trim();
    final nama = namaSiswaController.text.trim();

    if (nis.isEmpty) {
      AlertHelper.showWarning('Silakan masukkan NIS siswa');
      return;
    }
    if (nisn.isEmpty) {
      AlertHelper.showWarning('Silakan masukkan NISN siswa');
      return;
    }
    if (nama.isEmpty) {
      AlertHelper.showWarning('Silakan masukkan nama lengkap siswa');
      return;
    }

    isSavingStudent.value = true;
    try {
      if (editingStudent.value == null) {
        // Create student
        final result = await _studentService.createStudent(
          nis: nis,
          nisn: nisn,
          nama: nama,
          kelasId: selectedClass.value!.id,
          namaKelas: selectedClass.value!.namaKelas,
        );

        if (result != null) {
          Get.back(); // Close dialog
          AlertHelper.showSuccess('Siswa "$nama" berhasil ditambahkan');
          await loadStudentsForSelectedClass();
          _updateCurrentClassCount(students.length);
        } else {
          AlertHelper.showError('Gagal menambahkan data siswa');
        }
      } else {
        // Update student
        final id = editingStudent.value!.id;
        final result = await _studentService.updateStudent(
          id,
          nis: nis,
          nisn: nisn,
          nama: nama,
          kelasId: selectedClass.value!.id,
        );

        if (result != null) {
          Get.back(); // Close dialog
          AlertHelper.showSuccess('Data siswa "$nama" berhasil diperbarui');
          await loadStudentsForSelectedClass();
        } else {
          AlertHelper.showError('Gagal memperbarui data siswa');
        }
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan: $e');
    } finally {
      isSavingStudent.value = false;
    }
  }

  Future<void> confirmDeleteStudent(StudentModel student) async {
    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Hapus Data Siswa',
      message: 'Apakah Anda yakin ingin menghapus data siswa "${student.nama}" (NIS: ${student.nis})?',
      confirmText: 'Hapus Siswa',
      isDanger: true,
    );

    if (confirmed) {
      final res = await _studentService.deleteStudent(student.id);
      if (res['success'] == true) {
        AlertHelper.showSuccess(res['message'] ?? 'Data siswa berhasil dihapus');
        await loadStudentsForSelectedClass();
        _updateCurrentClassCount(students.length);
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal menghapus data siswa');
      }
    }
  }

  // ==================== EXCEL IMPORT METHODS ====================

  String get templateCsvContent =>
      "nis,nisn,nama\n241031,0088001031,I Made Pratama Jaya\n241032,0088001032,Ni Putu Sintya Dewi\n241033,0088001033,I Komang Agus Setiawan\n241034,0088001034,Kadek Dwi Lestari\n241035,0088001035,I Ketut Surya Dharma";

  void openImportDialog() {
    parsedImportStudents.clear();
    importError.value = '';
    pasteController.clear();
  }

  Future<void> copyTemplateToClipboard() async {
    await Clipboard.setData(ClipboardData(text: templateCsvContent));
    AlertHelper.showSuccess('Template Excel (.csv) berhasil disalin ke clipboard! Anda dapat menempelkannya di Excel atau formulir di bawah.');
  }

  Future<void> downloadTemplateFile({String format = 'xlsx'}) async {
    isDownloadingTemplate.value = true;
    try {
      final bytes = await _studentService.downloadTemplate(format: format);
      final fileName = format == 'xlsx' ? 'template_import_siswa.xlsx' : 'template_import_siswa.csv';
      final mimeType = format == 'xlsx'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : 'text/csv';

      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: mimeType,
        dialogTitle: 'Unduh Template Excel Data Siswa ($fileName)',
        type: FileType.custom,
        allowedExtensions: [format],
      );

      if (uri != null) {
        AlertHelper.showSuccess('Template $fileName berhasil diunduh!');
      }
    } catch (e) {
      AlertHelper.showError('Gagal mengunduh template: $e');
    } finally {
      isDownloadingTemplate.value = false;
    }
  }

  void parseCsvOrText(String text) {
    parsedImportStudents.clear();
    importError.value = '';

    final lines = const LineSplitter().convert(text).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) {
      importError.value = 'Tidak ada baris data yang ditemukan.';
      return;
    }

    final List<Map<String, String>> rows = [];
    bool isFirstLine = true;

    for (final line in lines) {
      // Detect delimiter
      String delimiter = ',';
      if (line.contains('\t')) {
        delimiter = '\t';
      } else if (line.contains(';')) {
        delimiter = ';';
      }

      final parts = line.split(delimiter).map((p) => p.trim().replaceAll('"', '')).toList();

      if (isFirstLine) {
        isFirstLine = false;
        final joined = parts.join(' ').toLowerCase();
        if (joined.contains('nis') || joined.contains('nama')) {
          continue; // skip header row
        }
      }

      if (parts.length >= 3) {
        final nis = parts[0];
        final nisn = parts[1];
        final nama = parts.sublist(2).join(' ').trim();
        if (nis.isNotEmpty && nama.isNotEmpty) {
          rows.add({'nis': nis, 'nisn': nisn, 'nama': nama});
        }
      }
    }

    if (rows.isEmpty) {
      importError.value = 'Format data tidak sesuai. Pastikan ada 3 kolom: NIS, NISN, Nama Lengkap.';
    } else {
      parsedImportStudents.assignAll(rows);
    }
  }

  Future<void> pickAndParseFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'xlsx'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();

        if (file.name.toLowerCase().endsWith('.xlsx')) {
          if (selectedClass.value == null) return;
          isImporting.value = true;
          try {
            final res = await _studentService.importStudentsFile(
              kelasId: selectedClass.value!.id,
              fileBytes: bytes,
              fileName: file.name,
            );

            if (res['success'] == true) {
              Get.back(); // close dialog
              final count = res['data']?['imported_count'] ?? 'beberapa';
              AlertHelper.showSuccess('Berhasil mengimpor $count siswa dari file Excel ${file.name}!');
              await loadStudentsForSelectedClass();
              _updateCurrentClassCount(students.length);
            } else {
              importError.value = res['message'] ?? 'Gagal mengimpor file Excel';
              AlertHelper.showError(importError.value);
            }
          } catch (e) {
            importError.value = 'Gagal memproses file Excel: $e';
            AlertHelper.showError(importError.value);
          } finally {
            isImporting.value = false;
          }
          return;
        }

        final content = utf8.decode(bytes);
        if (content.isNotEmpty) {
          pasteController.text = content;
          parseCsvOrText(content);
        }
      }
    } catch (e) {
      importError.value = 'Gagal membaca file: $e';
    }
  }

  Future<void> executeImport() async {
    if (selectedClass.value == null) return;

    if (parsedImportStudents.isEmpty) {
      AlertHelper.showWarning('Belum ada data siswa valid untuk diimpor.');
      return;
    }

    isImporting.value = true;
    try {
      final res = await _studentService.importStudents(
        kelasId: selectedClass.value!.id,
        students: parsedImportStudents,
      );

      if (res['success'] == true) {
        Get.back(); // close dialog
        final count = parsedImportStudents.length;
        AlertHelper.showSuccess('Berhasil mengimpor $count siswa ke kelas ${selectedClass.value!.namaKelas}!');
        await loadStudentsForSelectedClass();
        _updateCurrentClassCount(students.length);
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal mengimpor data siswa');
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan saat import: $e');
    } finally {
      isImporting.value = false;
    }
  }

  void _updateCurrentClassCount(int newCount) {
    if (selectedClass.value != null) {
      final old = selectedClass.value!;
      selectedClass.value = ClassModel(
        id: old.id,
        namaKelas: old.namaKelas,
        tingkat: old.tingkat,
        totalSiswa: newCount,
        totalJadwal: old.totalJadwal,
      );
    }
  }
}
