import '../models/user_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';

class TeacherService {
  final ApiService _api = ApiService();

  Future<List<UserModel>> getTeachers({String? role, String? query}) async {
    String url = '/guru';
    final Map<String, dynamic> params = {};
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'semua') {
      params['role'] = role.toLowerCase();
    }
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    if (params.isNotEmpty) {
      final qStr = Uri(queryParameters: params).query;
      url += '?$qStr';
    }

    final res = await _api.safeGet(url);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => UserModel.fromJson(e)).toList();
    }

    // Fallback offline / dummy
    var list = DummyDataProvider.dummyUsers;
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'semua') {
      list = list.where((u) => u.role.toLowerCase() == role.toLowerCase()).toList();
    }
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((u) =>
        u.nama.toLowerCase().contains(q) ||
        u.nip.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        (u.mataPelajaran != null && u.mataPelajaran!.toLowerCase().contains(q))
      ).toList();
    }
    return list;
  }

  Future<UserModel?> getTeacherById(int id) async {
    final res = await _api.safeGet('/guru/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return UserModel.fromJson(res.data['data']);
    }

    final matches = DummyDataProvider.dummyUsers.where((u) => u.id == id).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<UserModel?> createTeacher({
    required String nama,
    required String nip,
    required String email,
    required String password,
    String? mataPelajaran,
    String role = 'guru',
  }) async {
    final res = await _api.safePost('/guru', data: {
      'nama': nama.trim(),
      'nip': nip.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'mata_pelajaran': mataPelajaran?.trim(),
      'role': role,
    });

    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return UserModel.fromJson(res.data['data']);
    }

    // Fallback for offline / dummy
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newTeacher = UserModel(
      id: newId,
      nama: nama.trim(),
      nip: nip.trim(),
      email: email.trim().toLowerCase(),
      role: role,
      mataPelajaran: mataPelajaran?.trim(),
    );
    DummyDataProvider.addDummyTeacher(newTeacher);
    return newTeacher;
  }

  Future<UserModel?> updateTeacher(
    int id, {
    String? nama,
    String? nip,
    String? email,
    String? password,
    String? mataPelajaran,
    String? role,
  }) async {
    final Map<String, dynamic> body = {};
    if (nama != null) body['nama'] = nama.trim();
    if (nip != null) body['nip'] = nip.trim();
    if (email != null) body['email'] = email.trim().toLowerCase();
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (mataPelajaran != null) body['mata_pelajaran'] = mataPelajaran.trim();
    if (role != null) body['role'] = role;

    final res = await _api.safePut('/guru/$id', data: body);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return UserModel.fromJson(res.data['data']);
    }

    // Fallback for offline / dummy
    final existingList = DummyDataProvider.dummyUsers.where((u) => u.id == id).toList();
    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      final updated = existing.copyWith(
        nama: nama?.trim() ?? existing.nama,
        nip: nip?.trim() ?? existing.nip,
        email: email?.trim().toLowerCase() ?? existing.email,
        role: role ?? existing.role,
        mataPelajaran: mataPelajaran?.trim() ?? existing.mataPelajaran,
      );
      DummyDataProvider.updateDummyTeacher(updated);
      return updated;
    }
    return null;
  }

  Future<Map<String, dynamic>> deleteTeacher(int id) async {
    final res = await _api.safeDelete('/guru/$id');
    if (res != null) {
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {'success': true, 'message': 'Data guru berhasil dihapus'};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Gagal menghapus data guru'};
    }

    // Fallback for offline / dummy
    DummyDataProvider.deleteDummyTeacher(id);
    return {'success': true, 'message': 'Data guru berhasil dihapus'};
  }

  Future<Map<String, dynamic>> impersonateTeacher(int id) async {
    final res = await _api.safePost('/guru/$id/impersonate');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final token = res.data['data']['token'];
      final user = UserModel.fromJson(res.data['data']['user']);
      return {
        'success': true,
        'token': token,
        'user': user,
        'message': res.data['message'],
      };
    }

    // Fallback offline / dummy
    final matches = DummyDataProvider.dummyUsers.where((u) => u.id == id).toList();
    if (matches.isNotEmpty) {
      final user = matches.first;
      return {
        'success': true,
        'token': 'gurita_sanctum_token_dummy_impersonate_${user.id}',
        'user': user,
        'message': 'Berhasil login otomatis sebagai ${user.nama}',
      };
    }

    return {'success': false, 'message': 'Data guru tidak ditemukan'};
  }
}

