class StudentModel {
  final int id;
  final String nis;
  final String nisn;
  final String nama;
  final int kelasId;
  final String? namaKelas;

  StudentModel({
    required this.id,
    required this.nis,
    required this.nisn,
    required this.nama,
    required this.kelasId,
    this.namaKelas,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nis: json['nis'] ?? '',
      nisn: json['nisn'] ?? '',
      nama: json['nama'] ?? '',
      kelasId: json['kelas_id'] is int
          ? json['kelas_id']
          : int.tryParse(json['kelas_id']?.toString() ?? '0') ?? 0,
      namaKelas: json['nama_kelas'] ?? (json['kelas'] != null ? json['kelas']['nama_kelas'] : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nis': nis,
      'nisn': nisn,
      'nama': nama,
      'kelas_id': kelasId,
      'nama_kelas': namaKelas,
    };
  }
}
