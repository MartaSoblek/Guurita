class SubjectModel {
  final int id;
  final String kodeMapel;
  final String namaMapel;
  final int totalJadwal;

  SubjectModel({
    required this.id,
    required this.kodeMapel,
    required this.namaMapel,
    this.totalJadwal = 0,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      kodeMapel: json['kode_mapel'] ?? '',
      namaMapel: json['nama_mapel'] ?? '',
      totalJadwal: json['jadwal_count'] is int
          ? json['jadwal_count']
          : int.tryParse(json['jadwal_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_mapel': kodeMapel,
      'nama_mapel': namaMapel,
      'jadwal_count': totalJadwal,
    };
  }
}
