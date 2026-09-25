class AttendanceModel {
  final int? id;
  final int? jurnalId;
  final int siswaId;
  final String namaSiswa;
  final String nis;
  String status; // 'Hadir', 'Izin', 'Sakit', 'Alpa'
  String? keterangan;

  AttendanceModel({
    this.id,
    this.jurnalId,
    required this.siswaId,
    required this.namaSiswa,
    required this.nis,
    this.status = 'Hadir',
    this.keterangan,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      jurnalId: json['jurnal_id'] is int
          ? json['jurnal_id']
          : int.tryParse(json['jurnal_id']?.toString() ?? ''),
      siswaId: json['siswa_id'] is int
          ? json['siswa_id']
          : int.tryParse(json['siswa_id']?.toString() ?? '0') ?? 0,
      namaSiswa: json['siswa'] != null ? json['siswa']['nama'] : (json['nama_siswa'] ?? ''),
      nis: json['siswa'] != null ? json['siswa']['nis'] : (json['nis'] ?? ''),
      status: json['status'] ?? 'Hadir',
      keterangan: json['keterangan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (jurnalId != null) 'jurnal_id': jurnalId,
      'siswa_id': siswaId,
      'status': status,
      'keterangan': keterangan,
    };
  }

  AttendanceModel copyWith({
    int? id,
    int? jurnalId,
    int? siswaId,
    String? namaSiswa,
    String? nis,
    String? status,
    String? keterangan,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      jurnalId: jurnalId ?? this.jurnalId,
      siswaId: siswaId ?? this.siswaId,
      namaSiswa: namaSiswa ?? this.namaSiswa,
      nis: nis ?? this.nis,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
    );
  }
}
