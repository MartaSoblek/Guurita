import '../models/subject_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';

class SubjectService {
  final ApiService _api = ApiService();

  Future<List<SubjectModel>> getSubjects() async {
    final res = await _api.safeGet('/mapel');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => SubjectModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummySubjects;
  }

  Future<SubjectModel?> getSubjectById(int id) async {
    final res = await _api.safeGet('/mapel/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return SubjectModel.fromJson(res.data['data']);
    }
    final matches = DummyDataProvider.dummySubjects.where((s) => s.id == id).toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<SubjectModel?> createSubject({
    required String kodeMapel,
    required String namaMapel,
  }) async {
    final res = await _api.safePost('/mapel', data: {
      'kode_mapel': kodeMapel.toUpperCase().trim(),
      'nama_mapel': namaMapel.trim(),
    });

    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return SubjectModel.fromJson(res.data['data']);
    }

    // Fallback for dummy/offline
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newSubject = SubjectModel(
      id: newId,
      kodeMapel: kodeMapel.toUpperCase().trim(),
      namaMapel: namaMapel.trim(),
    );
    DummyDataProvider.addDummySubject(newSubject);
    return newSubject;
  }

  Future<SubjectModel?> updateSubject(
    int id, {
    String? kodeMapel,
    String? namaMapel,
  }) async {
    final Map<String, dynamic> body = {};
    if (kodeMapel != null) body['kode_mapel'] = kodeMapel.toUpperCase().trim();
    if (namaMapel != null) body['nama_mapel'] = namaMapel.trim();

    final res = await _api.safePut('/mapel/$id', data: body);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return SubjectModel.fromJson(res.data['data']);
    }

    // Fallback for dummy/offline
    final existingList = DummyDataProvider.dummySubjects.where((s) => s.id == id).toList();
    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      final updated = SubjectModel(
        id: id,
        kodeMapel: kodeMapel != null ? kodeMapel.toUpperCase().trim() : existing.kodeMapel,
        namaMapel: namaMapel != null ? namaMapel.trim() : existing.namaMapel,
      );
      DummyDataProvider.updateDummySubject(updated);
      return updated;
    }
    return null;
  }

  Future<Map<String, dynamic>> deleteSubject(int id) async {
    final res = await _api.safeDelete('/mapel/$id');
    if (res != null) {
      if (res.statusCode == 200 && res.data['success'] == true) {
        return {'success': true, 'message': 'Mata pelajaran berhasil dihapus'};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Gagal menghapus mata pelajaran'};
    }

    // Fallback for dummy/offline
    DummyDataProvider.deleteDummySubject(id);
    return {'success': true, 'message': 'Mata pelajaran berhasil dihapus'};
  }
}
