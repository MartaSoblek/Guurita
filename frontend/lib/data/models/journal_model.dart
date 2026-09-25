import 'attendance_model.dart';

class JournalModel {
  final int id;
  final int guruId;
  final int? jadwalId;
  final String tanggal;
  final String materi;
  final String kegiatan;
  final String? metode;
  final String? media;
  final String? kendala;
  final String? tindakLanjut;
  final String? catatan;
  final String? fotoKegiatan;
  final String? fotoKegiatanUrl;

  // Joined/Relational attributes
  final String? namaGuru;
  final String? namaKelas;
  final String? namaMapel;
  final String? jamMulai;
  final String? jamSelesai;
  final int totalHadir;
  final int totalIzin;
  final int totalSakit;
  final int totalAlpa;
  final List<AttendanceModel>? kehadiran;

  JournalModel({
    required this.id,
    required this.guruId,
    this.jadwalId,
    required this.tanggal,
    required this.materi,
    this.kegiatan = '',
    this.metode,
    this.media,
    this.kendala,
    this.tindakLanjut,
    this.catatan,
    this.fotoKegiatan,
    this.fotoKegiatanUrl,
    this.namaGuru,
    this.namaKelas,
    this.namaMapel,
    this.jamMulai,
    this.jamSelesai,
    this.totalHadir = 0,
    this.totalIzin = 0,
    this.totalSakit = 0,
    this.totalAlpa = 0,
    this.kehadiran,
  });

  bool get hasFotoKegiatan =>
      (fotoKegiatan != null && fotoKegiatan!.isNotEmpty) ||
      (fotoKegiatanUrl != null && fotoKegiatanUrl!.isNotEmpty);

  int get totalSiswa => totalHadir + totalIzin + totalSakit + totalAlpa;

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    List<AttendanceModel>? listKehadiran;
    if (json['kehadiran'] != null && json['kehadiran'] is List) {
      listKehadiran = (json['kehadiran'] as List)
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return JournalModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      guruId: json['guru_id'] is int
          ? json['guru_id']
          : int.tryParse(json['guru_id']?.toString() ?? '0') ?? 0,
      jadwalId: json['jadwal_id'] is int
          ? json['jadwal_id']
          : int.tryParse(json['jadwal_id']?.toString() ?? ''),
      tanggal: json['tanggal'] ?? '',
      materi: json['materi'] ?? '',
      kegiatan: json['kegiatan'] ?? '',
      metode: json['metode'],
      media: json['media'],
      kendala: json['kendala'],
      tindakLanjut: json['tindak_lanjut'],
      catatan: json['catatan'],
      fotoKegiatan: json['foto_kegiatan'],
      fotoKegiatanUrl: json['foto_kegiatan_url'],
      namaGuru: json['guru'] != null ? json['guru']['nama'] : json['nama_guru'],
      namaKelas: json['jadwal'] != null && json['jadwal']['kelas'] != null
          ? json['jadwal']['kelas']['nama_kelas']
          : json['nama_kelas'],
      namaMapel: json['jadwal'] != null && json['jadwal']['mapel'] != null
          ? json['jadwal']['mapel']['nama_mapel']
          : json['nama_mapel'],
      jamMulai: json['jadwal'] != null ? json['jadwal']['jam_mulai'] : json['jam_mulai'],
      jamSelesai: json['jadwal'] != null ? json['jadwal']['jam_selesai'] : json['jam_selesai'],
      totalHadir: json['total_hadir'] is int
          ? json['total_hadir']
          : int.tryParse(json['total_hadir']?.toString() ?? '0') ?? 0,
      totalIzin: json['total_izin'] is int
          ? json['total_izin']
          : int.tryParse(json['total_izin']?.toString() ?? '0') ?? 0,
      totalSakit: json['total_sakit'] is int
          ? json['total_sakit']
          : int.tryParse(json['total_sakit']?.toString() ?? '0') ?? 0,
      totalAlpa: json['total_alpa'] is int
          ? json['total_alpa']
          : int.tryParse(json['total_alpa']?.toString() ?? '0') ?? 0,
      kehadiran: listKehadiran,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guru_id': guruId,
      'jadwal_id': jadwalId,
      'tanggal': tanggal,
      'materi': materi,
      'kegiatan': kegiatan,
      'metode': metode,
      'media': media,
      'kendala': kendala,
      'tindak_lanjut': tindakLanjut,
      'catatan': catatan,
      'foto_kegiatan': fotoKegiatan,
      'foto_kegiatan_url': fotoKegiatanUrl,
      'nama_kelas': namaKelas,
      'nama_mapel': namaMapel,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      if (kehadiran != null) 'kehadiran': kehadiran!.map((e) => e.toJson()).toList(),
    };
  }
}
