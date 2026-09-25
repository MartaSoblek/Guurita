class ScheduleModel {
  final int id;
  final int guruId;
  final int kelasId;
  final int mapelId;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final String? namaGuru;
  final String? namaKelas;
  final String? namaMapel;

  ScheduleModel({
    required this.id,
    required this.guruId,
    required this.kelasId,
    required this.mapelId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    this.namaGuru,
    this.namaKelas,
    this.namaMapel,
  });

  String get formattedJam => '$jamMulai - $jamSelesai';

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      guruId: json['guru_id'] is int
          ? json['guru_id']
          : int.tryParse(json['guru_id']?.toString() ?? '0') ?? 0,
      kelasId: json['kelas_id'] is int
          ? json['kelas_id']
          : int.tryParse(json['kelas_id']?.toString() ?? '0') ?? 0,
      mapelId: json['mapel_id'] is int
          ? json['mapel_id']
          : int.tryParse(json['mapel_id']?.toString() ?? '0') ?? 0,
      hari: json['hari'] ?? '',
      jamMulai: json['jam_mulai'] != null
          ? json['jam_mulai'].toString().substring(0, 5)
          : '',
      jamSelesai: json['jam_selesai'] != null
          ? json['jam_selesai'].toString().substring(0, 5)
          : '',
      namaGuru: json['guru'] != null ? json['guru']['nama'] : json['nama_guru'],
      namaKelas: json['kelas'] != null ? json['kelas']['nama_kelas'] : json['nama_kelas'],
      namaMapel: json['mapel'] != null
          ? json['mapel']['nama_mapel']
          : (json['mata_pelajaran'] != null ? json['mata_pelajaran']['nama_mapel'] : json['nama_mapel']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guru_id': guruId,
      'kelas_id': kelasId,
      'mapel_id': mapelId,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'nama_guru': namaGuru,
      'nama_kelas': namaKelas,
      'nama_mapel': namaMapel,
    };
  }
}
