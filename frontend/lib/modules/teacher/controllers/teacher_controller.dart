import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/services/teacher_service.dart';
import '../../../data/services/subject_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/utils/alert_helper.dart';
import '../../../app/routes/app_routes.dart';

class TeacherController extends GetxController {
  final TeacherService _teacherService = TeacherService();
  final SubjectService _subjectService = SubjectService();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final teachers = <UserModel>[].obs;
  final availableSubjects = <SubjectModel>[].obs;
  final searchQuery = ''.obs;
  final selectedRoleFilter = 'Semua'.obs; // 'Semua', 'Guru', 'Admin'
  final isAdmin = false.obs;

  final editingTeacher = Rxn<UserModel>();
  final namaController = TextEditingController();
  final nipController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mapelController = TextEditingController();
  final selectedRole = 'guru'.obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = AuthService().currentUser;
    isAdmin.value = user?.isAdmin ?? false;
    loadTeachers();
    loadSubjects();
  }

  @override
  void onClose() {
    namaController.dispose();
    nipController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mapelController.dispose();
    super.onClose();
  }

  Future<void> loadTeachers() async {
    isLoading.value = true;
    try {
      final list = await _teacherService.getTeachers();
      teachers.assignAll(list);
    } catch (_) {
      // fallback handled in service
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSubjects() async {
    try {
      final list = await _subjectService.getSubjects();
      availableSubjects.assignAll(list);
    } catch (_) {
      // fallback
    }
  }

  List<UserModel> get filteredTeachers {
    var list = teachers.toList();

    // Filter by role
    if (selectedRoleFilter.value == 'Guru') {
      list = list.where((t) => t.role == 'guru').toList();
    } else if (selectedRoleFilter.value == 'Admin') {
      list = list.where((t) => t.role == 'admin').toList();
    }

    // Filter by search query
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((t) {
        return t.nama.toLowerCase().contains(q) ||
            t.nip.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q) ||
            (t.mataPelajaran != null && t.mataPelajaran!.toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  int get totalPendidik => teachers.length;
  int get totalGuru => teachers.where((t) => t.role == 'guru').length;
  int get totalAdmin => teachers.where((t) => t.role == 'admin').length;
  int get totalJadwalAktif => teachers.fold(0, (sum, t) => sum + t.totalJadwal);

  void openCreateDialog() {
    editingTeacher.value = null;
    namaController.clear();
    nipController.clear();
    emailController.clear();
    passwordController.clear();
    mapelController.clear();
    selectedRole.value = 'guru';
    isPasswordVisible.value = false;
  }

  void openEditDialog(UserModel teacher) {
    editingTeacher.value = teacher;
    namaController.text = teacher.nama;
    nipController.text = teacher.nip;
    emailController.text = teacher.email;
    passwordController.clear();
    mapelController.text = teacher.mataPelajaran ?? '';
    selectedRole.value = teacher.role;
    isPasswordVisible.value = false;
  }

  Future<void> saveTeacher() async {
    final nama = namaController.text.trim();
    final nip = nipController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final mapel = mapelController.text.trim();
    final role = selectedRole.value;

    if (nama.isEmpty) {
      AlertHelper.showWarning('Nama lengkap guru tidak boleh kosong');
      return;
    }
    if (nip.isEmpty) {
      AlertHelper.showWarning('NIP guru tidak boleh kosong');
      return;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      AlertHelper.showWarning('Silakan masukkan format email yang valid');
      return;
    }

    final isEdit = editingTeacher.value != null;

    if (!isEdit && password.length < 6) {
      AlertHelper.showWarning('Password baru minimal 6 karakter');
      return;
    }

    if (isEdit && password.isNotEmpty && password.length < 6) {
      AlertHelper.showWarning('Password baru minimal 6 karakter jika ingin diubah');
      return;
    }

    isSaving.value = true;
    try {
      if (!isEdit) {
        // Create new teacher
        final result = await _teacherService.createTeacher(
          nama: nama,
          nip: nip,
          email: email,
          password: password,
          mataPelajaran: mapel.isNotEmpty ? mapel : null,
          role: role,
        );

        if (result != null) {
          Get.back(); // close dialog
          AlertHelper.showSuccess('Data guru "$nama" berhasil ditambahkan');
          await loadTeachers();
        } else {
          AlertHelper.showError('Gagal menambahkan data guru');
        }
      } else {
        // Update teacher
        final id = editingTeacher.value!.id;
        final result = await _teacherService.updateTeacher(
          id,
          nama: nama,
          nip: nip,
          email: email,
          password: password.isNotEmpty ? password : null,
          mataPelajaran: mapel.isNotEmpty ? mapel : '',
          role: role,
        );

        if (result != null) {
          Get.back(); // close dialog
          AlertHelper.showSuccess('Data guru "$nama" berhasil diperbarui');
          await loadTeachers();
        } else {
          AlertHelper.showError('Gagal memperbarui data guru');
        }
      }
    } catch (e) {
      AlertHelper.showError('Terjadi kesalahan: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmDelete(UserModel teacher) async {
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId == teacher.id) {
      AlertHelper.showWarning('Anda tidak dapat menghapus akun Anda sendiri.');
      return;
    }

    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Hapus Data Guru',
      message: 'Apakah Anda yakin ingin menghapus "${teacher.nama}" (${teacher.nip}) dari sistem sekolah?\n\nTindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus Guru',
      isDanger: true,
    );

    if (confirmed) {
      final res = await _teacherService.deleteTeacher(teacher.id);
      if (res['success'] == true) {
        AlertHelper.showSuccess(res['message'] ?? 'Data guru berhasil dihapus');
        await loadTeachers();
      } else {
        AlertHelper.showError(res['message'] ?? 'Gagal menghapus data guru');
      }
    }
  }

  Future<void> loginAsTeacher(UserModel teacher) async {
    final currentUserId = AuthService().currentUser?.id;
    if (currentUserId == teacher.id) {
      AlertHelper.showWarning('Anda saat ini sudah aktif masuk menggunakan akun "${teacher.nama}".');
      return;
    }

    final confirmed = await AlertHelper.showConfirmDialog(
      title: 'Login Sebagai ${teacher.role == 'admin' ? 'Administrator' : 'Guru'}',
      message: 'Apakah Anda ingin dialihkan ke halaman login dan otomatis masuk menggunakan akun ini?\n\n'
          '• Nama  : ${teacher.nama}\n'
          '• NIP   : ${teacher.nip}\n'
          '• Email : ${teacher.email}\n'
          '• Peran : ${teacher.role.toUpperCase()}\n'
          '• Mapel : ${teacher.mataPelajaran ?? "-"}\n\n'
          'Sistem akan mengalihkan Anda ke tautan login dan secara otomatis memproses masuk dengan akun ${teacher.nama}.',
      confirmText: 'Lanjutkan & Login Otomatis',
    );

    if (!confirmed) return;

    // Optional: Request backend impersonation token if admin session is live
    String? impersonateToken;
    try {
      final res = await _teacherService.impersonateTeacher(teacher.id);
      if (res['success'] == true && res['token'] != null) {
        impersonateToken = res['token'];
      }
    } catch (_) {
      // offline/dummy fallback handles this gracefully
    }

    // Cleanly log out current admin session
    await AuthService().logout();

    final Map<String, dynamic> loginArgs = {
      'auto_login': true,
      'email': teacher.email,
      'teacher_name': teacher.nama,
      'teacher': teacher.toJson(),
    };
    if (impersonateToken != null) {
      loginArgs['impersonate_token'] = impersonateToken;
    }

    // Redirect to login route with arguments & web query parameters
    Get.offAllNamed(
      Routes.login,
      arguments: loginArgs,
      parameters: {
        'email': teacher.email,
        'auto': 'true',
      },
    );
  }
}

