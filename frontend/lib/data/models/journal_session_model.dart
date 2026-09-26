import 'schedule_model.dart';
import 'journal_model.dart';
import '../../core/utils/date_formatter.dart';

class JournalSessionModel {
  final int jadwalId;
  final String tanggal;
  final String hari;
  final bool isToday;
  final String jamMulai;
  final String jamSelesai;
  final int kelasId;
  final String namaKelas;
  final String? tingkat;
  final int mapelId;
  final String namaMapel;
  final String? kodeMapel;
  final int guruId;
  final String namaGuru;
  final String status; // 'sudah_diisi' | 'belum_diisi'
  final int? jurnalId;
  final String? materi;
  final String? kegiatan;
  final String? fotoKegiatan;
  final String? fotoKegiatanUrl;
  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpa;
  final int totalKehadiran;

  JournalSessionModel({
    required this.jadwalId,
    required this.tanggal,
    required this.hari,
    required this.isToday,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kelasId,
    required this.namaKelas,
    this.tingkat,
    required this.mapelId,
    required this.namaMapel,
    this.kodeMapel,
    required this.guruId,
    required this.namaGuru,
    required this.status,
    this.jurnalId,
    this.materi,
    this.kegiatan,
    this.fotoKegiatan,
    this.fotoKegiatanUrl,
    this.totalHadir = 0,
    this.totalIzin = 0,
    this.totalSakit = 0,
    this.totalAlpa = 0,
    this.totalKehadiran = 0,
  });

  bool get isSudahDiisi => status == 'sudah_diisi';
  bool get isBelumDiisi => status == 'belum_diisi';
  bool get hasKehadiran => isSudahDiisi && (totalKehadiran > 0 || totalHadir > 0);
  bool get hasFoto =>
      (fotoKegiatan != null && fotoKegiatan!.isNotEmpty) ||
      (fotoKegiatanUrl != null && fotoKegiatanUrl!.isNotEmpty);

  factory JournalSessionModel.fromSchedule(
    ScheduleModel schedule, {
    String? tanggal,
    JournalModel? existingJournal,
  }) {
    final tgl = tanggal ?? DateFormatter.getTodayDateIso();
    final hasJournal = existingJournal != null;
    return JournalSessionModel(
      jadwalId: schedule.id,
      tanggal: tgl,
      hari: schedule.hari,
      isToday: true,
      jamMulai: schedule.jamMulai,
      jamSelesai: schedule.jamSelesai,
      kelasId: schedule.kelasId,
      namaKelas: schedule.namaKelas ?? 'Kelas',
      mapelId: schedule.mapelId,
      namaMapel: schedule.namaMapel ?? 'Mata Pelajaran',
      guruId: schedule.guruId,
      namaGuru: schedule.namaGuru ?? '',
      status: hasJournal ? 'sudah_diisi' : 'belum_diisi',
      jurnalId: existingJournal?.id,
      materi: existingJournal?.materi,
      kegiatan: existingJournal?.kegiatan,
      fotoKegiatan: existingJournal?.fotoKegiatan,
      fotoKegiatanUrl: existingJournal?.fotoKegiatanUrl,
      totalHadir: existingJournal?.totalHadir ?? 0,
      totalIzin: existingJournal?.totalIzin ?? 0,
      totalSakit: existingJournal?.totalSakit ?? 0,
      totalAlpa: existingJournal?.totalAlpa ?? 0,
      totalKehadiran: (existingJournal?.totalHadir ?? 0) +
          (existingJournal?.totalIzin ?? 0) +
          (existingJournal?.totalSakit ?? 0) +
          (existingJournal?.totalAlpa ?? 0),
    );
  }

  factory JournalSessionModel.fromJson(Map<String, dynamic> json) {
    return JournalSessionModel(
      jadwalId: json['jadwal_id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      hari: json['hari'] ?? '',
      isToday: json['is_today'] ?? false,
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      kelasId: json['kelas_id'] ?? 0,
      namaKelas: json['nama_kelas'] ?? '',
      tingkat: json['tingkat'],
      mapelId: json['mapel_id'] ?? 0,
      namaMapel: json['nama_mapel'] ?? '',
      kodeMapel: json['kode_mapel'],
      guruId: json['guru_id'] ?? 0,
      namaGuru: json['nama_guru'] ?? '',
      status: json['status'] ?? 'belum_diisi',
      jurnalId: json['jurnal_id'],
      materi: json['materi'],
      kegiatan: json['kegiatan'],
      fotoKegiatan: json['foto_kegiatan'],
      fotoKegiatanUrl: json['foto_kegiatan_url'],
      totalHadir: json['total_hadir'] ?? 0,
      totalIzin: json['total_izin'] ?? 0,
      totalSakit: json['total_sakit'] ?? 0,
      totalAlpa: json['total_alpa'] ?? 0,
      totalKehadiran: json['total_kehadiran'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jadwal_id': jadwalId,
      'tanggal': tanggal,
      'hari': hari,
      'is_today': isToday,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
      'tingkat': tingkat,
      'mapel_id': mapelId,
      'nama_mapel': namaMapel,
      'kode_mapel': kodeMapel,
      'guru_id': guruId,
      'nama_guru': namaGuru,
      'status': status,
      'jurnal_id': jurnalId,
      'materi': materi,
      'kegiatan': kegiatan,
      'foto_kegiatan': fotoKegiatan,
      'foto_kegiatan_url': fotoKegiatanUrl,
      'total_hadir': totalHadir,
      'total_izin': totalIzin,
      'total_sakit': totalSakit,
      'total_alpa': totalAlpa,
      'total_kehadiran': totalKehadiran,
    };
  }
}
