import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/journal_model.dart';
import '../models/journal_session_model.dart';
import '../models/attendance_model.dart';
import '../providers/dummy_data_provider.dart';
import 'api_service.dart';
import 'auth_service.dart';

class JournalService {
  final ApiService _api = ApiService();

  // In-memory fallback journal storage
  static final List<JournalModel> _localJournals = List.from(DummyDataProvider.dummyJournals);

  Future<List<JournalModel>> getJournals({
    String? search,
    String? tanggal,
    int? kelasId,
    int? mapelId,
    int? guruId,
  }) async {
    final currentUser = AuthService().currentUser;
    final targetGuruId = guruId ?? (currentUser != null && !currentUser.isAdmin ? currentUser.id : null);

    final Map<String, dynamic> params = {};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tanggal != null && tanggal.isNotEmpty) params['tanggal'] = tanggal;
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (mapelId != null) params['mapel_id'] = mapelId;
    if (targetGuruId != null) params['guru_id'] = targetGuruId;

    final res = await _api.safeGet('/jurnal', queryParameters: params);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final List data = res.data['data'];
      return data.map((e) => JournalModel.fromJson(e)).toList();
    }

    // Local filter fallback
    var list = List<JournalModel>.from(_localJournals);
    if (targetGuruId != null) {
      list = list.where((j) => j.guruId == targetGuruId).toList();
    }
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      list = list
          .where((j) =>
              j.materi.toLowerCase().contains(query) ||
              (j.namaGuru?.toLowerCase().contains(query) ?? false) ||
              (j.namaKelas?.toLowerCase().contains(query) ?? false) ||
              (j.namaMapel?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    if (tanggal != null && tanggal.isNotEmpty) {
      list = list.where((j) => j.tanggal == tanggal).toList();
    }
    return list;
  }

  Future<JournalModel?> getJournalById(int id) async {
    final res = await _api.safeGet('/jurnal/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return JournalModel.fromJson(res.data['data']);
    }

    try {
      return _localJournals.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createJournal({
    required int? jadwalId,
    required String tanggal,
    required String materi,
    String? kegiatan,
    String? metode,
    String? media,
    String? kendala,
    String? tindakLanjut,
    String? catatan,
    String? namaKelas,
    String? namaMapel,
    String? jamMulai,
    String? jamSelesai,
    List<AttendanceModel>? attendanceList,
    List<int>? photoBytes,
    String? photoName,
  }) async {
    Response? res;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final Map<String, dynamic> formMap = {
        'jadwal_id': ?jadwalId,
        'tanggal': tanggal,
        'materi': materi,
        if (kegiatan != null && kegiatan.isNotEmpty) 'kegiatan': kegiatan,
        if (metode != null && metode.isNotEmpty) 'metode': metode,
        if (media != null && media.isNotEmpty) 'media': media,
        if (kendala != null && kendala.isNotEmpty) 'kendala': kendala,
        if (tindakLanjut != null && tindakLanjut.isNotEmpty) 'tindak_lanjut': tindakLanjut,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
        'foto_kegiatan': MultipartFile.fromBytes(photoBytes, filename: photoName ?? 'foto_kegiatan.jpg'),
      };

      if (attendanceList != null) {
        for (var i = 0; i < attendanceList.length; i++) {
          formMap['kehadiran[$i][siswa_id]'] = attendanceList[i].siswaId;
          formMap['kehadiran[$i][status]'] = attendanceList[i].status;
          if (attendanceList[i].keterangan != null && attendanceList[i].keterangan!.isNotEmpty) {
            formMap['kehadiran[$i][keterangan]'] = attendanceList[i].keterangan;
          }
        }
      }

      final formData = FormData.fromMap(formMap);
      res = await _api.safePost('/jurnal', data: formData);
    } else {
      final payload = {
        'jadwal_id': ?jadwalId,
        'tanggal': tanggal,
        'materi': materi,
        'kegiatan': kegiatan,
        'metode': metode,
        'media': media,
        'kendala': kendala,
        'tindak_lanjut': tindakLanjut,
        'catatan': catatan,
        'kehadiran': ?attendanceList?.map((a) => a.toJson()).toList(),
      };
      res = await _api.safePost('/jurnal', data: payload);
    }

    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return {
        'success': true,
        'message': res.data['message'] ?? 'Jurnal mengajar berhasil disimpan',
        'data': JournalModel.fromJson(res.data['data']),
      };
    }

    if (res != null && res.data != null && res.data is Map && res.data['success'] == false) {
      return {
        'success': false,
        'message': res.data['message'] ?? 'Gagal menyimpan jurnal ke server',
      };
    }

    // Local fallback creation
    int hadir = 0, izin = 0, sakit = 0, alpa = 0;
    if (attendanceList != null) {
      for (final a in attendanceList) {
        if (a.status == 'Hadir') hadir++;
        if (a.status == 'Izin') izin++;
        if (a.status == 'Sakit') sakit++;
        if (a.status == 'Alpa') alpa++;
      }
    } else {
      hadir = 30;
    }

    String? localPhotoData;
    if (photoBytes != null && photoBytes.isNotEmpty) {
      localPhotoData = 'data:image/jpeg;base64,${base64Encode(photoBytes)}';
    }

    final currentUser = AuthService().currentUser;
    final newJournal = JournalModel(
      id: _localJournals.length + 1,
      guruId: currentUser?.id ?? 1,
      jadwalId: jadwalId,
      tanggal: tanggal,
      materi: materi,
      kegiatan: kegiatan ?? '',
      metode: metode,
      media: media,
      kendala: kendala,
      tindakLanjut: tindakLanjut,
      catatan: catatan,
      fotoKegiatan: localPhotoData,
      fotoKegiatanUrl: localPhotoData,
      namaGuru: currentUser?.nama ?? 'I Made Surya, S.Kom',
      namaKelas: namaKelas ?? 'XI TKJ 1',
      namaMapel: namaMapel ?? 'IoT',
      jamMulai: jamMulai ?? '07:30',
      jamSelesai: jamSelesai ?? '09:00',
      totalHadir: hadir,
      totalIzin: izin,
      totalSakit: sakit,
      totalAlpa: alpa,
      kehadiran: attendanceList,
    );

    _localJournals.insert(0, newJournal);
    return {
      'success': true,
      'message': 'Jurnal mengajar berhasil disimpan',
      'data': newJournal,
    };
  }

  Future<Map<String, dynamic>> updateJournal(
    int id,
    Map<String, dynamic> data, {
    List<int>? photoBytes,
    String? photoName,
    bool removePhoto = false,
  }) async {
    Response? res;
    if ((photoBytes != null && photoBytes.isNotEmpty) || removePhoto) {
      final Map<String, dynamic> formMap = {};
      data.forEach((key, val) {
        if (key == 'kehadiran' && val is List) {
          for (var i = 0; i < val.length; i++) {
            final item = val[i] as Map<String, dynamic>;
            formMap['kehadiran[$i][siswa_id]'] = item['siswa_id'];
            formMap['kehadiran[$i][status]'] = item['status'];
            if (item['keterangan'] != null) {
              formMap['kehadiran[$i][keterangan]'] = item['keterangan'];
            }
          }
        } else if (val != null) {
          formMap[key] = val;
        }
      });

      if (photoBytes != null && photoBytes.isNotEmpty) {
        formMap['foto_kegiatan'] = MultipartFile.fromBytes(photoBytes, filename: photoName ?? 'foto_kegiatan.jpg');
      } else if (removePhoto) {
        formMap['hapus_foto'] = '1';
      }

      final formData = FormData.fromMap(formMap);
      res = await _api.safePost('/jurnal/$id', data: formData);
    } else {
      res = await _api.safePut('/jurnal/$id', data: data);
    }

    if (res != null && (res.statusCode == 200 || res.statusCode == 201) && res.data['success'] == true) {
      return {'success': true, 'message': res.data['message'] ?? 'Jurnal berhasil diperbarui'};
    }

    if (res != null && res.data != null && res.data is Map && res.data['success'] == false) {
      return {'success': false, 'message': res.data['message'] ?? 'Gagal memperbarui jurnal'};
    }

    final index = _localJournals.indexWhere((j) => j.id == id);
    if (index != -1) {
      final old = _localJournals[index];
      String? updatedPhoto = old.fotoKegiatan;
      if (photoBytes != null && photoBytes.isNotEmpty) {
        updatedPhoto = 'data:image/jpeg;base64,${base64Encode(photoBytes)}';
      } else if (removePhoto) {
        updatedPhoto = null;
      }

      _localJournals[index] = JournalModel(
        id: old.id,
        guruId: old.guruId,
        jadwalId: old.jadwalId,
        tanggal: data['tanggal'] ?? old.tanggal,
        materi: data['materi'] ?? old.materi,
        kegiatan: data['kegiatan'] ?? old.kegiatan,
        metode: data['metode'] ?? old.metode,
        media: data['media'] ?? old.media,
        kendala: data['kendala'] ?? old.kendala,
        tindakLanjut: data['tindak_lanjut'] ?? old.tindakLanjut,
        catatan: data['catatan'] ?? old.catatan,
        fotoKegiatan: updatedPhoto,
        fotoKegiatanUrl: updatedPhoto,
        namaGuru: old.namaGuru,
        namaKelas: old.namaKelas,
        namaMapel: old.namaMapel,
        jamMulai: old.jamMulai,
        jamSelesai: old.jamSelesai,
        totalHadir: old.totalHadir,
        totalIzin: old.totalIzin,
        totalSakit: old.totalSakit,
        totalAlpa: old.totalAlpa,
      );
    }
    return {'success': true, 'message': 'Jurnal berhasil diperbarui'};
  }

  Future<bool> deleteJournal(int id) async {
    final res = await _api.safeDelete('/jurnal/$id');
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      return true;
    }
    if (res != null && res.data != null && res.data is Map && res.data['success'] == false) {
      return false;
    }
    _localJournals.removeWhere((j) => j.id == id);
    return true;
  }

  Future<Map<String, dynamic>> getSemesterSessions({
    int? guruId,
    int? kelasId,
    String? status,
    String? search,
  }) async {
    final Map<String, dynamic> params = {};
    if (guruId != null) params['guru_id'] = guruId;
    if (kelasId != null) params['kelas_id'] = kelasId;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await _api.safeGet('/jurnal/sesi-semester', queryParameters: params);
    if (res != null && res.statusCode == 200 && res.data['success'] == true) {
      final data = res.data['data'];
      final List sessionList = data['sessions'] ?? [];
      return {
        'semester': data['semester'] ?? 'Semester Berjalan',
        'total_sesi': data['total_sesi'] ?? 0,
        'total_sudah_diisi': data['total_sudah_diisi'] ?? 0,
        'total_belum_diisi': data['total_belum_diisi'] ?? 0,
        'total_hari_ini': data['total_hari_ini'] ?? 0,
        'sessions': sessionList.map((e) => JournalSessionModel.fromJson(e)).toList(),
      };
    }

    // Offline / Dummy fallback
    return _generateDummySemesterSessions(
      guruId: guruId,
      kelasId: kelasId,
      status: status,
      search: search,
    );
  }

  Map<String, dynamic> _generateDummySemesterSessions({
    int? guruId,
    int? kelasId,
    String? status,
    String? search,
  }) {
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentYear = now.year;
    final isGanjil = now.month >= 7;
    final startDate = isGanjil ? DateTime(currentYear, 7, 1) : DateTime(currentYear, 1, 1);
    final semesterName = isGanjil ? 'Semester Ganjil $currentYear/${currentYear + 1}' : 'Semester Genap ${currentYear - 1}/$currentYear';

    var schedules = DummyDataProvider.dummySchedules;
    if (guruId != null) {
      schedules = schedules.where((s) => s.guruId == guruId).toList();
    }
    if (kelasId != null) {
      schedules = schedules.where((s) => s.kelasId == kelasId).toList();
    }

    final dayMap = {
      DateTime.monday: 'Senin',
      DateTime.tuesday: 'Selasa',
      DateTime.wednesday: 'Rabu',
      DateTime.thursday: 'Kamis',
      DateTime.friday: 'Jumat',
      DateTime.saturday: 'Sabtu',
      DateTime.sunday: 'Minggu',
    };

    final List<JournalSessionModel> sessions = [];
    DateTime curr = DateTime(now.year, now.month, now.day);

    while (!curr.isBefore(startDate)) {
      final dateStr = '${curr.year.toString().padLeft(4, '0')}-${curr.month.toString().padLeft(2, '0')}-${curr.day.toString().padLeft(2, '0')}';
      final dayName = dayMap[curr.weekday] ?? '';

      final matching = schedules.where((s) => s.hari.trim().toLowerCase() == dayName.toLowerCase()).toList();
      for (final s in matching) {
        final existing = _localJournals.where((j) => j.jadwalId == s.id && j.tanggal == dateStr).toList();
        final isFilled = existing.isNotEmpty;
        final j = isFilled ? existing.first : null;

        sessions.add(JournalSessionModel(
          jadwalId: s.id,
          tanggal: dateStr,
          hari: dayName,
          isToday: dateStr == todayStr,
          jamMulai: s.jamMulai,
          jamSelesai: s.jamSelesai,
          kelasId: s.kelasId,
          namaKelas: s.namaKelas ?? '',
          tingkat: s.namaKelas?.split(' ').first,
          mapelId: s.mapelId,
          namaMapel: s.namaMapel ?? '',
          kodeMapel: null,
          guruId: s.guruId,
          namaGuru: s.namaGuru ?? '',
          status: isFilled ? 'sudah_diisi' : 'belum_diisi',
          jurnalId: j?.id,
          materi: j?.materi,
          kegiatan: j?.kegiatan,
          totalHadir: isFilled ? (j?.totalHadir ?? 30) : 0,
          totalIzin: isFilled ? (j?.totalIzin ?? 1) : 0,
          totalSakit: isFilled ? (j?.totalSakit ?? 1) : 0,
          totalAlpa: isFilled ? (j?.totalAlpa ?? 0) : 0,
          totalKehadiran: isFilled ? ((j?.totalSiswa ?? 0) > 0 ? j!.totalSiswa : 32) : 0,
        ));
      }
      curr = curr.subtract(const Duration(days: 1));
    }

    final totalSesi = sessions.length;
    final totalSudah = sessions.where((s) => s.isSudahDiisi).length;
    final totalBelum = sessions.where((s) => s.isBelumDiisi).length;
    final totalHariIni = sessions.where((s) => s.isToday).length;

    var filtered = sessions;
    if (status == 'belum_diisi' || status == 'sudah_diisi') {
      filtered = filtered.where((s) => s.status == status).toList();
    } else if (status == 'hari_ini') {
      filtered = filtered.where((s) => s.isToday).toList();
    }

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where((s) =>
              s.namaKelas.toLowerCase().contains(q) ||
              s.namaMapel.toLowerCase().contains(q) ||
              s.namaGuru.toLowerCase().contains(q) ||
              (s.materi?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    return {
      'semester': semesterName,
      'total_sesi': totalSesi,
      'total_sudah_diisi': totalSudah,
      'total_belum_diisi': totalBelum,
      'total_hari_ini': totalHariIni,
      'sessions': filtered,
    };
  }
}
