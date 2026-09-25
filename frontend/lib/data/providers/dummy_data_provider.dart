import '../models/user_model.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';
import '../models/schedule_model.dart';
import '../models/journal_model.dart';

class DummyDataProvider {
  // 1. Users (Admin & Teachers)
  static final List<UserModel> dummyUsers = [
    UserModel(
      id: 99,
      nama: 'Administrator',
      nip: '197901012003121002',
      email: 'admin@smkn1abang.sch.id',
      role: 'admin',
      mataPelajaran: 'Semua Mata Pelajaran',
      foto: null,
    ),
    UserModel(
      id: 1,
      nama: 'I Made Surya, S.Kom',
      nip: '198507122010011008',
      email: 'surya@smkn1abang.sch.id',
      role: 'guru',
      mataPelajaran: 'IoT & Dasar Komputer',
      foto: null,
    ),
    UserModel(
      id: 2,
      nama: 'Ni Luh Dewi, S.Pd',
      nip: '198904252014022003',
      email: 'dewi@smkn1abang.sch.id',
      role: 'guru',
      mataPelajaran: 'Administrasi Infrastruktur Jaringan',
      foto: null,
    ),
  ];

  // 2. Classes
  static final List<ClassModel> dummyClasses = [
    ClassModel(id: 1, namaKelas: 'X TKJ', tingkat: 'X', totalSiswa: 30, totalJadwal: 2),
    ClassModel(id: 2, namaKelas: 'XI TKJ 1', tingkat: 'XI', totalSiswa: 30, totalJadwal: 3),
    ClassModel(id: 3, namaKelas: 'XI TKJ 2', tingkat: 'XI', totalSiswa: 30, totalJadwal: 2),
  ];

  static void addDummyClass(ClassModel cls) {
    dummyClasses.add(cls);
  }

  static void updateDummyClass(ClassModel cls) {
    final index = dummyClasses.indexWhere((c) => c.id == cls.id);
    if (index != -1) {
      dummyClasses[index] = cls;
    }
  }

  static bool deleteDummyClass(int id) {
    dummyClasses.removeWhere((c) => c.id == id);
    return true;
  }

  // 3. Subjects
  static final List<SubjectModel> dummySubjects = [
    SubjectModel(id: 1, kodeMapel: 'IOT-01', namaMapel: 'IoT'),
    SubjectModel(id: 2, kodeMapel: 'DSK-02', namaMapel: 'Dasar Komputer'),
    SubjectModel(id: 3, kodeMapel: 'AIJ-03', namaMapel: 'Administrasi Infrastruktur Jaringan'),
  ];

  static void addDummySubject(SubjectModel subject) {
    dummySubjects.add(subject);
  }

  static void updateDummySubject(SubjectModel subject) {
    final index = dummySubjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      dummySubjects[index] = subject;
    }
  }

  static bool deleteDummySubject(int id) {
    dummySubjects.removeWhere((s) => s.id == id);
    return true;
  }

  // 4. Students generator (30 per class)
  static List<StudentModel>? _dummyStudents;

  static List<StudentModel> get dummyStudents {
    _dummyStudents ??= _generateDummyStudents();
    return _dummyStudents!;
  }

  static List<StudentModel> _generateDummyStudents() {
    final List<StudentModel> list = [];
    final firstNames = [
      'I Wayan', 'I Made', 'I Nyoman', 'I Ketut', 'Ni Wayan',
      'Ni Made', 'Ni Nyoman', 'Ni Ketut', 'Kadek', 'Komang',
      'Gede', 'Putu', 'Anak Agung', 'Ida Bagus', 'Desak',
      'Agus', 'Budi', 'Rizky', 'Dian', 'Siti',
      'Ahmad', 'Dimas', 'Eka', 'Bayu', 'Mega',
      'Satria', 'Wira', 'Lestari', 'Pradnya', 'Widya'
    ];
    final lastNames = [
      'Artana', 'Sudarsana', 'Suartika', 'Widiarta', 'Wiguna',
      'Pratama', 'Saputra', 'Adnyana', 'Kusuma', 'Mahendra',
      'Gunawan', 'Wijaya', 'Santosa', 'Darmo', 'Setiawan',
      'Hidayat', 'Nugraha', 'Permana', 'Laksana', 'Kencana',
      'Utama', 'Suryani', 'Indrawan', 'Baskara', 'Purnomo',
      'Yasa', 'Astawa', 'Mahardika', 'Dharmawan', 'Sucipto'
    ];

    int idCounter = 1;
    for (int k = 0; k < dummyClasses.length; k++) {
      final cls = dummyClasses[k];
      for (int i = 0; i < 30; i++) {
        final nis = '${cls.tingkat == "X" ? "24" : "23"}${1000 + idCounter}';
        final nisn = '008${8000000 + idCounter}';
        final name = '${firstNames[i % firstNames.length]} ${lastNames[(i + k * 5) % lastNames.length]}';
        list.add(
          StudentModel(
            id: idCounter,
            nis: nis,
            nisn: nisn,
            nama: name,
            kelasId: cls.id,
            namaKelas: cls.namaKelas,
          ),
        );
        idCounter++;
      }
    }
    return list;
  }

  static void addDummyStudent(StudentModel student) {
    dummyStudents.add(student);
  }

  static void updateDummyStudent(StudentModel student) {
    final index = dummyStudents.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      dummyStudents[index] = student;
    }
  }

  static bool deleteDummyStudent(int id) {
    dummyStudents.removeWhere((s) => s.id == id);
    return true;
  }

  // 5. Schedules
  static final List<ScheduleModel> dummySchedules = [
    ScheduleModel(
      id: 1,
      guruId: 1,
      kelasId: 2,
      mapelId: 1,
      hari: 'Senin',
      jamMulai: '07:30',
      jamSelesai: '09:00',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 1',
      namaMapel: 'IoT',
    ),
    ScheduleModel(
      id: 2,
      guruId: 1,
      kelasId: 3,
      mapelId: 1,
      hari: 'Senin',
      jamMulai: '09:15',
      jamSelesai: '11:45',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 2',
      namaMapel: 'IoT',
    ),
    ScheduleModel(
      id: 3,
      guruId: 1,
      kelasId: 1,
      mapelId: 2,
      hari: 'Selasa',
      jamMulai: '08:00',
      jamSelesai: '10:15',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'X TKJ',
      namaMapel: 'Dasar Komputer',
    ),
    ScheduleModel(
      id: 4,
      guruId: 1,
      kelasId: 2,
      mapelId: 1,
      hari: 'Rabu',
      jamMulai: '07:30',
      jamSelesai: '09:45',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 1',
      namaMapel: 'IoT',
    ),
    ScheduleModel(
      id: 5,
      guruId: 1,
      kelasId: 3,
      mapelId: 1,
      hari: 'Rabu',
      jamMulai: '10:00',
      jamSelesai: '12:15',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 2',
      namaMapel: 'IoT',
    ),
    ScheduleModel(
      id: 6,
      guruId: 1,
      kelasId: 1,
      mapelId: 2,
      hari: 'Kamis',
      jamMulai: '07:30',
      jamSelesai: '09:45',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'X TKJ',
      namaMapel: 'Dasar Komputer',
    ),
    ScheduleModel(
      id: 7,
      guruId: 2,
      kelasId: 2,
      mapelId: 3,
      hari: 'Jumat',
      jamMulai: '07:30',
      jamSelesai: '10:00',
      namaGuru: 'Ni Luh Dewi, S.Pd',
      namaKelas: 'XI TKJ 1',
      namaMapel: 'Administrasi Infrastruktur Jaringan',
    ),
  ];

  static void addDummySchedule(ScheduleModel schedule) {
    dummySchedules.add(schedule);
  }

  static void updateDummySchedule(ScheduleModel schedule) {
    final index = dummySchedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      dummySchedules[index] = schedule;
    }
  }

  static void deleteDummySchedule(int id) {
    dummySchedules.removeWhere((s) => s.id == id);
  }

  // 6. Pre-filled Journals
  static List<JournalModel> get dummyJournals => [
    JournalModel(
      id: 1,
      guruId: 1,
      jadwalId: 1,
      tanggal: '2026-09-21',
      materi: 'Pengenalan Sensor ESP32 dan Arsitektur IoT',
      kegiatan: 'Penyampaian materi arsitektur IoT dan pengenalan pinout ESP32, dilanjutkan praktik instalasi board pada Arduino IDE.',
      metode: 'Demonstrasi dan Praktikum Terbimbing',
      media: 'Modul ESP32, Breadboard, LCD Proyektor',
      kendala: 'Dua modul kabel data USB mengalami gangguan koneksi ke laptop siswa.',
      tindakLanjut: 'Mengganti kabel data cadangan dari laboratorium.',
      catatan: 'Seluruh siswa antusias mengikuti praktikum dasar GPIO.',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 1',
      namaMapel: 'IoT',
      jamMulai: '07:30',
      jamSelesai: '09:00',
      totalHadir: 28,
      totalIzin: 1,
      totalSakit: 1,
      totalAlpa: 0,
    ),
    JournalModel(
      id: 2,
      guruId: 1,
      jadwalId: 2,
      tanggal: '2026-09-21',
      materi: 'Protokol Komunikasi MQTT pada Sistem IoT',
      kegiatan: 'Pengujian publish dan subscribe topik sensor suhu menggunakan broker publik HiveMQ.',
      metode: 'Studi Kasus & Lab Hands-on',
      media: 'ESP32 NodeMCU, Sensor DHT22, Wi-Fi Sekolah',
      kendala: 'Trafik Wi-Fi sempat melambat di awal sesi.',
      tindakLanjut: 'Membagi koneksi ke hotspot access point lab TKJ.',
      catatan: 'Semua kelompok berhasil menampilkan data di dashboard MQTT.',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 2',
      namaMapel: 'IoT',
      jamMulai: '09:15',
      jamSelesai: '11:45',
      totalHadir: 29,
      totalIzin: 1,
      totalSakit: 0,
      totalAlpa: 0,
    ),
    JournalModel(
      id: 3,
      guruId: 1,
      jadwalId: 3,
      tanggal: '2026-09-22',
      materi: 'Arsitektur Von Neumann dan Komponen Motherboard',
      kegiatan: 'Identifikasi fisik komponen CPU, RAM, Slot PCIe, dan Chipset pada unit PC praktik.',
      metode: 'Diskusi Kelompok & Praktik Bongkar Pasang',
      media: 'Toolkit Obeng, Motherboard Trainer, Antistatik',
      kendala: 'Tidak ada kendala berarti.',
      tindakLanjut: 'Persiapan materi modul power supply untuk pekan depan.',
      catatan: 'Siswa kelas X sangat tertib mematuhi SOP K3 kelistrikan.',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'X TKJ',
      namaMapel: 'Dasar Komputer',
      jamMulai: '08:00',
      jamSelesai: '10:15',
      totalHadir: 30,
      totalIzin: 0,
      totalSakit: 0,
      totalAlpa: 0,
    ),
  ];
}
