class UserModel {
  final int id;
  final String nama;
  final String nip;
  final String email;
  final String role;
  final String? foto;
  final String? mataPelajaran;
  final int totalJadwal;
  final int totalJurnal;

  UserModel({
    required this.id,
    required this.nama,
    required this.nip,
    required this.email,
    this.role = 'guru',
    this.foto,
    this.mataPelajaran,
    this.totalJadwal = 0,
    this.totalJurnal = 0,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama'] ?? '',
      nip: json['nip'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'guru',
      foto: json['foto'],
      mataPelajaran: json['mata_pelajaran'] ?? json['mapel'],
      totalJadwal: json['jadwal_count'] ?? json['total_jadwal'] ?? 0,
      totalJurnal: json['jurnal_count'] ?? json['total_jurnal'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'nip': nip,
      'email': email,
      'role': role,
      'foto': foto,
      'mata_pelajaran': mataPelajaran,
      'jadwal_count': totalJadwal,
      'jurnal_count': totalJurnal,
    };
  }

  UserModel copyWith({
    int? id,
    String? nama,
    String? nip,
    String? email,
    String? role,
    String? foto,
    String? mataPelajaran,
    int? totalJadwal,
    int? totalJurnal,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nip: nip ?? this.nip,
      email: email ?? this.email,
      role: role ?? this.role,
      foto: foto ?? this.foto,
      mataPelajaran: mataPelajaran ?? this.mataPelajaran,
      totalJadwal: totalJadwal ?? this.totalJadwal,
      totalJurnal: totalJurnal ?? this.totalJurnal,
    );
  }
}
