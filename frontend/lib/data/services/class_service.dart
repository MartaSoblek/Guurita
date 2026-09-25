import '../models/class_model.dart';
import '../models/student_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';

class ClassService {
  final ApiService _api = ApiService();

  Future<List<ClassModel>> getClasses() async {
    final res = await _api.safeGet('/kelas');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => ClassModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummyClasses;
  }

  Future<ClassModel?> getClassById(int id) async {
    final res = await _api.safeGet('/kelas/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return ClassModel.fromJson(res.data['data']);
    }
    final matches = DummyDataProvider.dummyClasses.where((c) => c.id == id).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<ClassModel?> createClass({
    required String namaKelas,
    required String tingkat,
  }) async {
    final res = await _api.safePost('/kelas', data: {
      'nama_kelas': namaKelas.trim(),
      'tingkat': tingkat.toUpperCase().trim(),
    });

    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return ClassModel.fromJson(res.data['data']);
    }

    // Fallback for dummy/offline
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newClass = ClassModel(
      id: newId,
      namaKelas: namaKelas.trim(),
      tingkat: tingkat.toUpperCase().trim(),
      totalSiswa: 0,
      totalJadwal: 0,
    );
    DummyDataProvider.addDummyClass(newClass);
    return newClass;
  }

  Future<ClassModel?> updateClass(
    int id, {
    String? namaKelas,
    String? tingkat,
  }) async {
    final Map<String, dynamic> body = {};
    if (namaKelas != null) body['nama_kelas'] = namaKelas.trim();
    if (tingkat != null) body['tingkat'] = tingkat.toUpperCase().trim();

    final res = await _api.safePut('/kelas/$id', data: body);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return ClassModel.fromJson(res.data['data']);
    }

    // Fallback for dummy/offline
    final existingList = DummyDataProvider.dummyClasses.where((c) => c.id == id).toList();
    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      final updated = ClassModel(
        id: id,
        namaKelas: namaKelas != null ? namaKelas.trim() : existing.namaKelas,
        tingkat: tingkat != null ? tingkat.toUpperCase().trim() : existing.tingkat,
        totalSiswa: existing.totalSiswa,
        totalJadwal: existing.totalJadwal,
      );
      DummyDataProvider.updateDummyClass(updated);
      return updated;
    }
    return null;
  }

  Future<Map<String, dynamic>> deleteClass(int id) async {
    final res = await _api.safeDelete('/kelas/$id');
    if (res != null) {
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {'success': true, 'message': 'Data kelas berhasil dihapus'};
      }
      return {
        'success': false,
        'message': res.data['message'] ?? 'Gagal menghapus data kelas',
      };
    }

    // Fallback for dummy/offline
    DummyDataProvider.deleteDummyClass(id);
    return {'success': true, 'message': 'Data kelas berhasil dihapus'};
  }

  Future<List<StudentModel>> getStudentsByClass(int classId) async {
    final res = await _api.safeGet('/kelas/$classId/siswa');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => StudentModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummyStudents.where((s) => s.kelasId == classId).toList();
  }
}
