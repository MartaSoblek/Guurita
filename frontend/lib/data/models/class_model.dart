class ClassModel {
  final int id;
  final String namaKelas;
  final String tingkat;
  final int totalSiswa;
  final int totalJadwal;

  ClassModel({
    required this.id,
    required this.namaKelas,
    required this.tingkat,
    this.totalSiswa = 0,
    this.totalJadwal = 0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    final siswaVal = json['siswa_count'] ?? json['total_siswa'];
    final jadwalVal = json['jadwal_count'] ?? json['total_jadwal'];

    return ClassModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      namaKelas: json['nama_kelas'] ?? '',
      tingkat: json['tingkat'] ?? '',
      totalSiswa: siswaVal is int ? siswaVal : int.tryParse(siswaVal?.toString() ?? '0') ?? 0,
      totalJadwal: jadwalVal is int ? jadwalVal : int.tryParse(jadwalVal?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kelas': namaKelas,
      'tingkat': tingkat,
      'total_siswa': totalSiswa,
      'total_jadwal': totalJadwal,
    };
  }
}
