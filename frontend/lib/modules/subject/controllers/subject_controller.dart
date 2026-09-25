import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/services/subject_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';

class SubjectController extends GetxController {
  final SubjectService _subjectService = SubjectService();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final subjects = <SubjectModel>[].obs;
  final searchQuery = ''.obs;
  final isAdmin = false.obs;

  final editingSubject = Rxn<SubjectModel>();
  final kodeController = TextEditingController();
  final namaController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    loadSubjects();
  }

  @override
  void onClose() {
    kodeController.dispose();
    namaController.dispose();
    super.onClose();
  }

  Future<void> loadSubjects() async {
    isLoading.value = true;
    try {
      final list = await _subjectService.getSubjects();
      subjects.assignAll(list);
    } catch (_) {
      // fallback
    } finally {
      isLoading.value = false;
    }
  }

  List<SubjectModel> get filteredSubjects {
    if (searchQuery.value.trim().isEmpty) {
      return subjects;
    }
    final q = searchQuery.value.toLowerCase().trim();
    return subjects.where((s) {
      return s.namaMapel.toLowerCase().contains(q) || s.kodeMapel.toLowerCase().contains(q);
    }).toList();
  }

  void openCreateDialog() {
    editingSubject.value = null;
    kodeController.clear();
    namaController.clear();
  }

  void openEditDialog(SubjectModel subject) {
    editingSubject.value = subject;
    kodeController.text = subject.kodeMapel;
    namaController.text = subject.namaMapel;
  }

  Future<void> saveSubject() async {
    final kode = kodeController.text.trim();
    final nama = namaController.text.trim();

    if (kode.isEmpty) {
      AlertHelper.showWarning('Silakan masukkan kode mata pelajaran');
      return;
    }
    if (nama.isEmpty) {
      AlertHelper.showWarning('Silakan masukkan nama mata pelajaran');
      return;
    }

    isSaving.value = true;
    try {
      if (editingSubject.value == null) {
        // Create
        final result = await _subjectService.createSubject(
          kodeMapel: kode,
          namaMapel: nama,
        );

        if (result != null) {
          Get.back(); // Close modal
          AlertHelper.showSuccess('Mata pelajaran "$nama" berhasil ditambahkan');
          await loadSubjects();
        } else {
          AlertHelper.showError('Gagal menambahkan mata pelajaran');
        }
      } else {
        // Update
        final id = editingSubject.value!.id;
        final result = await _subjectService.updateSubject(
          id,
          kodeMapel: kode,
          namaMapel: nama,
        );

        if (result != null) {
          Get.back(); // Close modal
          AlertHelper.showSuccess('Mata pelajaran "$nama" berhasil diperbarui');
          await loadSubjects();
        } else {
          AlertHelper.showError('Gagal memperbarui mata pelajaran');
        }
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmDelete(SubjectModel subject) async {
    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Hapus Mata Pelajaran',
      message: 'Apakah Anda yakin ingin menghapus mata pelajaran "${subject.namaMapel}" (${subject.kodeMapel})?',
      confirmText: 'Hapus Mapel',
      isDanger: true,
    );

    if (confirmed) {
      final res = await _subjectService.deleteSubject(subject.id);
      if (res['success'] == true) {
        AlertHelper.showSuccess(res['message'] ?? 'Mata pelajaran berhasil dihapus');
        await loadSubjects();
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal menghapus mata pelajaran');
      }
    }
  }
}
