import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ScheduleService {
  final ApiService _api = ApiService();

  Future<List<ScheduleModel>> getAllSchedules({int? guruId}) async {
    final Map<String, dynamic> params = {};
    if (guruId != null) params['guru_id'] = guruId;

    final res = await _api.safeGet('/jadwal', queryParameters: params);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => ScheduleModel.fromJson(e)).toList();
    }
    if (guruId != null) {
      return DummyDataProvider.dummySchedules.where((s) => s.guruId == guruId).toList();
    }
    final currentUser = AuthService().currentUser;
    if (currentUser != null && !currentUser.isAdmin) {
      return DummyDataProvider.dummySchedules.where((s) => s.guruId == currentUser.id).toList();
    }
    return DummyDataProvider.dummySchedules;
  }

  Future<List<ScheduleModel>> getTodaySchedules({int? guruId}) async {
    final Map<String, dynamic> params = {};
    if (guruId != null) params['guru_id'] = guruId;

    final res = await _api.safeGet('/jadwal/hari-ini', queryParameters: params);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => ScheduleModel.fromJson(e)).toList();
    }

    // Default to today's schedules from dummy (e.g. Senin/Rabu)
    var list = DummyDataProvider.dummySchedules.where((s) => s.hari == 'Rabu' || s.hari == 'Senin').toList();
    if (guruId != null) {
      list = list.where((s) => s.guruId == guruId).toList();
    }
    return list;
  }

  Future<List<UserModel>> getGuruList() async {
    final res = await _api.safeGet('/guru');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummyUsers.where((u) => !u.isAdmin).toList();
  }

  Future<ScheduleModel?> getScheduleById(int id) async {
    final res = await _api.safeGet('/jadwal/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return ScheduleModel.fromJson(res.data['data']);
    }
    return DummyDataProvider.dummySchedules.firstWhere(
      (s) => s.id == id,
      orElse: () => DummyDataProvider.dummySchedules.first,
    );
  }

  Future<List<ClassModel>> getClasses() async {
    final res = await _api.safeGet('/kelas');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => ClassModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummyClasses;
  }

  Future<List<StudentModel>> getStudentsByClass(int classId) async {
    final res = await _api.safeGet('/kelas/$classId/siswa');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => StudentModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummyStudents.where((s) => s.kelasId == classId).toList();
  }

  Future<List<SubjectModel>> getSubjects() async {
    final res = await _api.safeGet('/mapel');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => SubjectModel.fromJson(e)).toList();
    }
    return DummyDataProvider.dummySubjects;
  }

  Future<ScheduleModel?> createSchedule({
    required int kelasId,
    required int mapelId,
    required String hari,
    required String jamMulai,
    required String jamSelesai,
    int? guruId,
    String? namaGuru,
    String? namaKelas,
    String? namaMapel,
  }) async {
    final currentUser = AuthService().currentUser;
    if (currentUser != null && !currentUser.isAdmin) {
      guruId = currentUser.id;
    }

    final Map<String, dynamic> body = {
      'kelas_id': kelasId,
      'mapel_id': mapelId,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
    };
    if (guruId != null) body['guru_id'] = guruId;

    final res = await _api.safePost('/jadwal', data: body);
    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return ScheduleModel.fromJson(res.data['data']);
    }

    // Fallback for dummy / offline mode
    final newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newSchedule = ScheduleModel(
      id: newId,
      guruId: guruId ?? (currentUser?.id ?? 1),
      kelasId: kelasId,
      mapelId: mapelId,
      hari: hari,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      namaGuru: namaGuru ?? (currentUser?.nama ?? 'Guru Pengampu'),
      namaKelas: namaKelas ?? 'Kelas',
      namaMapel: namaMapel ?? 'Mata Pelajaran',
    );
    DummyDataProvider.addDummySchedule(newSchedule);
    return newSchedule;
  }

  Future<ScheduleModel?> updateSchedule(
    int id, {
    int? kelasId,
    int? mapelId,
    String? hari,
    String? jamMulai,
    String? jamSelesai,
    int? guruId,
    String? namaGuru,
    String? namaKelas,
    String? namaMapel,
  }) async {
    final currentUser = AuthService().currentUser;
    if (currentUser != null && !currentUser.isAdmin) {
      guruId = currentUser.id;
    }

    final Map<String, dynamic> body = {};
    if (kelasId != null) body['kelas_id'] = kelasId;
    if (mapelId != null) body['mapel_id'] = mapelId;
    if (hari != null) body['hari'] = hari;
    if (jamMulai != null) body['jam_mulai'] = jamMulai;
    if (jamSelesai != null) body['jam_selesai'] = jamSelesai;
    if (guruId != null) body['guru_id'] = guruId;

    final res = await _api.safePut('/jadwal/$id', data: body);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return ScheduleModel.fromJson(res.data['data']);
    }

    // Fallback for dummy / offline mode
    final existingList = DummyDataProvider.dummySchedules.where((s) => s.id == id).toList();
    if (existingList.isNotEmpty) {
      final existing = existingList.first;
      // Teacher can only update their own schedule
      if (currentUser != null && !currentUser.isAdmin && existing.guruId != currentUser.id) {
        return null;
      }

      final updated = ScheduleModel(
        id: id,
        guruId: (currentUser != null && !currentUser.isAdmin) ? currentUser.id : (guruId ?? existing.guruId),
        kelasId: kelasId ?? existing.kelasId,
        mapelId: mapelId ?? existing.mapelId,
        hari: hari ?? existing.hari,
        jamMulai: jamMulai ?? existing.jamMulai,
        jamSelesai: jamSelesai ?? existing.jamSelesai,
        namaGuru: namaGuru ?? existing.namaGuru,
        namaKelas: namaKelas ?? existing.namaKelas,
        namaMapel: namaMapel ?? existing.namaMapel,
      );
      DummyDataProvider.updateDummySchedule(updated);
      return updated;
    }
    return null;
  }

  Future<bool> deleteSchedule(int id) async {
    final currentUser = AuthService().currentUser;
    final existingList = DummyDataProvider.dummySchedules.where((s) => s.id == id).toList();
    if (existingList.isNotEmpty && currentUser != null && !currentUser.isAdmin && existingList.first.guruId != currentUser.id) {
      return false;
    }

    final res = await _api.safeDelete('/jadwal/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return true;
    }

    // Fallback for dummy / offline mode
    DummyDataProvider.deleteDummySchedule(id);
    return true;
  }
}
