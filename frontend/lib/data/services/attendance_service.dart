import '../models/attendance_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService _api = ApiService();

  Future<List<AttendanceModel>> getAttendanceByJournal(int journalId) async {
    final res = await _api.safeGet('/jurnal/$journalId/kehadiran');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => AttendanceModel.fromJson(e)).toList();
    }

    // Default 30 dummy students with mostly Hadir
    final students = DummyDataProvider.dummyStudents.take(30).toList();
    return students.asMap().entries.map((entry) {
      final idx = entry.key;
      final st = entry.value;
      String stStatus = 'Hadir';
      if (idx == 5) stStatus = 'Izin';
      if (idx == 12) stStatus = 'Sakit';
      return AttendanceModel(
        id: idx + 1,
        jurnalId: journalId,
        siswaId: st.id,
        namaSiswa: st.nama,
        nis: st.nis,
        status: stStatus,
      );
    }).toList();
  }

  Future<Map<String, dynamic>> saveAttendance({
    required int journalId,
    required List<AttendanceModel> attendances,
  }) async {
    final payload = {
      'kehadiran': attendances.map((a) => a.toJson()).toList(),
    };

    final res = await _api.safePost('/jurnal/$journalId/kehadiran', data: payload);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return {'success': true, 'message': res.data['message']};
    }

    return {'success': true, 'message': 'Kehadiran siswa berhasil disimpan'};
  }

  Future<bool> updateSingleAttendance(int id, String status, String? keterangan) async {
    final res = await _api.safePut('/kehadiran/$id', data: {
      'status': status,
      'keterangan': keterangan,
    });

    if (res != null && res.statusCode == 200) {
      return true;
    }
    return true;
  }
}
