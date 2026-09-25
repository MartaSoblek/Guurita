import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/student_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';

class StudentService {
  final ApiService _api = ApiService();

  Future<List<StudentModel>> getStudentsByClass(int classId) async {
    final res = await _api.safeGet('/api/siswa', queryParameters: {'kelas_id': classId});
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => StudentModel.fromJson(e)).toList();
    }

    // Secondary API route fallback
    final resSecondary = await _api.safeGet('/kelas/$classId/siswa');
    if (resSecondary != null && resSecondary.statusCode == 200 && resSecondary.data['success'] == true) {
      final List data = resSecondary.data['data'];
      return data.map((e) => StudentModel.fromJson(e)).toList();
    }

    // Fallback for offline/dummy
    return DummyDataProvider.dummyStudents.where((s) => s.kelasId == classId).toList();
  }

  Future<StudentModel?> getStudentById(int id) async {
    final res = await _api.safeGet('/siswa/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return StudentModel.fromJson(res.data['data']);
    }
    final matches = DummyDataProvider.dummyStudents.where((s) => s.id == id).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<StudentModel?> createStudent({
    required String nis,
    required String nisn,
    required String nama,
    required int kelasId,
    String? namaKelas,
  }) async {
    final res = await _api.safePost('/siswa', data: {
      'nis': nis.trim(),
      'nisn': nisn.trim(),
      'nama': nama.trim(),
      'kelas_id': kelasId,
    });

    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return StudentModel.fromJson(res.data['data']);
    }

    // Fallback for offline/dummy
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newStudent = StudentModel(
      id: newId,
      nis: nis.trim(),
      nisn: nisn.trim(),
      nama: nama.trim(),
      kelasId: kelasId,
      namaKelas: namaKelas,
    );
    DummyDataProvider.addDummyStudent(newStudent);
    return newStudent;
  }

  Future<StudentModel?> updateStudent(
    int id, {
    String? nis,
    String? nisn,
    String? nama,
    int? kelasId,
  }) async {
    final Map<String, dynamic> body = {};
    if (nis != null) body['nis'] = nis.trim();
    if (nisn != null) body['nisn'] = nisn.trim();
    if (nama != null) body['nama'] = nama.trim();
    if (kelasId != null) body['kelas_id'] = kelasId;

    final res = await _api.safePut('/siswa/$id', data: body);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return StudentModel.fromJson(res.data['data']);
    }

    // Fallback for offline/dummy
    final existingList = DummyDataProvider.dummyStudents.where((s) => s.id == id).toList();
    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      final updated = StudentModel(
        id: id,
        nis: nis != null ? nis.trim() : existing.nis,
        nisn: nisn != null ? nisn.trim() : existing.nisn,
        nama: nama != null ? nama.trim() : existing.nama,
        kelasId: kelasId ?? existing.kelasId,
        namaKelas: existing.namaKelas,
      );
      DummyDataProvider.updateDummyStudent(updated);
      return updated;
    }
    return null;
  }

  Future<Map<String, dynamic>> deleteStudent(int id) async {
    final res = await _api.safeDelete('/siswa/$id');
    if (res != null) {
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {'success': true, 'message': 'Data siswa berhasil dihapus'};
      }
      return {
        'success': false,
        'message': res.data['message'] ?? 'Gagal menghapus data siswa',
      };
    }

    // Fallback for offline/dummy
    DummyDataProvider.deleteDummyStudent(id);
    return {'success': true, 'message': 'Data siswa berhasil dihapus'};
  }

  Future<Map<String, dynamic>> importStudents({
    required int kelasId,
    required List<Map<String, String>> students,
  }) async {
    final res = await _api.safePost('/siswa/import', data: {
      'kelas_id': kelasId,
      'students': students,
    });

    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return {
        'success': true,
        'message': res.data['message'] ?? 'Import data siswa berhasil',
        'data': res.data['data'],
      };
    }

    // Fallback for offline/dummy
    int imported = 0;
    for (final s in students) {
      final newId = DateTime.now().millisecondsSinceEpoch % 100000 + imported;
      final newStudent = StudentModel(
        id: newId,
        nis: s['nis'] ?? '',
        nisn: s['nisn'] ?? '',
        nama: s['nama'] ?? '',
        kelasId: kelasId,
      );
      DummyDataProvider.addDummyStudent(newStudent);
      imported++;
    }

    return {
      'success': true,
      'message': 'Berhasil mengimpor $imported siswa.',
      'data': {'imported_count': imported},
    };
  }

  Future<Map<String, dynamic>> importStudentsFile({
    required int kelasId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'kelas_id': kelasId,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      final res = await _api.dio.post('/siswa/import', data: formData);
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {
          'success': true,
          'message': res.data['message'] ?? 'Import berkas siswa berhasil.',
          'data': res.data['data'],
        };
      }
      return {
        'success': false,
        'message': res.data['message'] ?? 'Gagal mengimpor file siswa',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan saat mengunggah berkas: $e',
      };
    }
  }

  Future<List<int>> downloadTemplate({String format = 'xlsx'}) async {
    try {
      final res = await _api.dio.get(
        '/siswa/template',
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.data != null && res.data is List<int>) {
        return List<int>.from(res.data);
      }
    } catch (_) {}

    // Fallback if offline / server unavailable
    if (format == 'csv') {
      return utf8.encode(
        "nis,nisn,nama\n241031,0088001031,I Made Pratama Jaya\n241032,0088001032,Ni Putu Sintya Dewi\n241033,0088001033,I Komang Agus Setiawan\n241034,0088001034,Kadek Dwi Lestari\n241035,0088001035,I Ketut Surya Dharma\n",
      );
    } else {
      // Return decoded authentic .xlsx base64 template
      return base64Decode(
        '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',
      );
    }
  }
}
