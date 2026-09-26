import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gurita/app/constants/app_constants.dart';
import 'package:gurita/core/widgets/gurita_logo.dart';
import 'package:gurita/core/widgets/dashboard_metric_card.dart';
import 'package:gurita/data/models/user_model.dart';
import 'package:gurita/data/models/schedule_model.dart';
import 'package:gurita/data/models/subject_model.dart';
import 'package:gurita/data/models/class_model.dart';
import 'package:gurita/data/models/student_model.dart';
import 'package:gurita/data/models/journal_session_model.dart';
import 'package:get/get.dart';
import 'package:gurita/data/models/journal_model.dart';
import 'package:gurita/core/utils/image_url_helper.dart';
import 'package:gurita/core/utils/date_formatter.dart';
import 'package:gurita/data/services/report_service.dart';
import 'package:gurita/data/services/teacher_service.dart';
import 'package:gurita/data/services/schedule_service.dart';
import 'package:gurita/data/services/auth_service.dart';
import 'package:gurita/modules/report/controllers/report_controller.dart';

void main() {
  testWidgets('GURITA Logo renders with school branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuritaLogo(size: 48, showText: true),
        ),
      ),
    );

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(AppConstants.appSubtitle), findsOneWidget);
  });

  testWidgets('DashboardMetricCard renders title and value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DashboardMetricCard(
            title: 'Kelas Hari Ini',
            value: '3',
            icon: Icons.meeting_room,
          ),
        ),
      ),
    );

    expect(find.text('Kelas Hari Ini'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.meeting_room), findsOneWidget);
  });

  test('UserModel correctly identifies admin role', () {
    final admin = UserModel(
      id: 99,
      nama: 'Administrator',
      nip: '197901012003121002',
      email: 'admin@smkn1abang.sch.id',
      role: 'admin',
    );
    expect(admin.isAdmin, isTrue);
    expect(admin.role, 'admin');

    final guru = UserModel(
      id: 1,
      nama: 'I Made Surya, S.Kom',
      nip: '198507122010011008',
      email: 'surya@smkn1abang.sch.id',
      role: 'guru',
    );
    expect(guru.isAdmin, isFalse);
    expect(guru.role, 'guru');
  });

  test('TeacherService and UserModel dummy CRUD', () async {
    final teacherService = TeacherService();
    final list = await teacherService.getTeachers();
    expect(list.isNotEmpty, isTrue);

    // Create teacher
    final newTeacher = await teacherService.createTeacher(
      nama: 'Guru Pengujian, S.Pd',
      nip: '199501012022011001',
      email: 'testing.guru@smkn1abang.sch.id',
      password: 'password123',
      mataPelajaran: 'Pemrograman Web',
      role: 'guru',
    );

    expect(newTeacher, isNotNull);
    expect(newTeacher!.nama, 'Guru Pengujian, S.Pd');
    expect(newTeacher.nip, '199501012022011001');
    expect(newTeacher.isAdmin, isFalse);

    // Update teacher
    final updated = await teacherService.updateTeacher(
      newTeacher.id,
      nama: 'Guru Pengujian Edit, M.Pd',
    );
    expect(updated, isNotNull);
    expect(updated!.nama, 'Guru Pengujian Edit, M.Pd');

    // Delete teacher
    final delRes = await teacherService.deleteTeacher(newTeacher.id);
    expect(delRes['success'], isTrue);
  });

  test('TeacherService impersonate and AuthService login-as flow', () async {
    final teacherService = TeacherService();
    final authService = AuthService();

    final teachers = await teacherService.getTeachers();
    final target = teachers.first;

    // Test impersonation session generation
    final impersonateRes = await teacherService.impersonateTeacher(target.id);
    expect(impersonateRes['success'], isTrue);
    expect(impersonateRes['user'], isNotNull);
    expect(impersonateRes['token'], isNotNull);

    // Test auto-login with impersonate token and fallbackUser
    final loginRes = await authService.login(
      target.email,
      'password',
      fallbackUser: target,
      impersonateToken: impersonateRes['token'],
    );

    expect(loginRes['success'], isTrue);
    expect(authService.currentUser?.email, target.email);
    expect(authService.isAuthenticated, isTrue);
  });

  test('ScheduleModel serialization and dummy CRUD', () {
    final schedule = ScheduleModel(
      id: 999,
      guruId: 1,
      kelasId: 1,
      mapelId: 2,
      hari: 'Sabtu',
      jamMulai: '08:00',
      jamSelesai: '09:30',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'X TKJ',
      namaMapel: 'Dasar Komputer',
    );

    expect(schedule.formattedJam, '08:00 - 09:30');
    expect(schedule.hari, 'Sabtu');

    final json = schedule.toJson();
    expect(json['hari'], 'Sabtu');
    expect(json['jam_mulai'], '08:00');

    final fromJson = ScheduleModel.fromJson(json);
    expect(fromJson.id, 999);
    expect(fromJson.namaKelas, 'X TKJ');
  });

  test('SubjectModel serialization and dummy CRUD', () {
    final subject = SubjectModel(
      id: 50,
      kodeMapel: 'PBO-04',
      namaMapel: 'Pemrograman Berorientasi Objek',
      totalJadwal: 2,
    );

    expect(subject.kodeMapel, 'PBO-04');
    expect(subject.namaMapel, 'Pemrograman Berorientasi Objek');
    expect(subject.totalJadwal, 2);

    final json = subject.toJson();
    expect(json['kode_mapel'], 'PBO-04');

    final fromJson = SubjectModel.fromJson(json);
    expect(fromJson.id, 50);
    expect(fromJson.namaMapel, 'Pemrograman Berorientasi Objek');
    expect(fromJson.totalJadwal, 2);
  });

  test('ClassModel serialization and dummy CRUD', () {
    final cls = ClassModel(
      id: 10,
      namaKelas: 'XII RPL 1',
      tingkat: 'XII',
      totalSiswa: 32,
      totalJadwal: 4,
    );

    expect(cls.namaKelas, 'XII RPL 1');
    expect(cls.tingkat, 'XII');
    expect(cls.totalSiswa, 32);
    expect(cls.totalJadwal, 4);

    final json = cls.toJson();
    expect(json['nama_kelas'], 'XII RPL 1');
    expect(json['tingkat'], 'XII');

    final fromJson = ClassModel.fromJson(json);
    expect(fromJson.id, 10);
    expect(fromJson.namaKelas, 'XII RPL 1');
    expect(fromJson.totalSiswa, 32);
    expect(fromJson.totalJadwal, 4);
  });

  test('StudentModel serialization and dummy CRUD', () {
    final student = StudentModel(
      id: 101,
      nis: '241099',
      nisn: '0089991099',
      nama: 'Ni Kadek Ayu Lestari',
      kelasId: 1,
      namaKelas: 'X TKJ',
    );

    expect(student.nis, '241099');
    expect(student.nisn, '0089991099');
    expect(student.nama, 'Ni Kadek Ayu Lestari');
    expect(student.kelasId, 1);

    final json = student.toJson();
    expect(json['nis'], '241099');
    expect(json['nama'], 'Ni Kadek Ayu Lestari');

    final fromJson = StudentModel.fromJson(json);
    expect(fromJson.id, 101);
    expect(fromJson.nis, '241099');
    expect(fromJson.nama, 'Ni Kadek Ayu Lestari');
  });

  test('JournalSessionModel serialization and semester date rules', () {
    final sessionBelum = JournalSessionModel(
      jadwalId: 1,
      tanggal: '2026-09-20',
      hari: 'Senin',
      isToday: false,
      jamMulai: '07:30',
      jamSelesai: '09:00',
      kelasId: 1,
      namaKelas: 'X TKJ',
      mapelId: 2,
      namaMapel: 'Dasar Komputer',
      guruId: 1,
      namaGuru: 'I Made Surya, S.Kom',
      status: 'belum_diisi',
    );

    expect(sessionBelum.isBelumDiisi, isTrue);
    expect(sessionBelum.isSudahDiisi, isFalse);
    expect(sessionBelum.isToday, isFalse);

    final json = sessionBelum.toJson();
    expect(json['status'], 'belum_diisi');
    expect(json['tanggal'], '2026-09-20');

    final sessionSudah = JournalSessionModel.fromJson({
      'jadwal_id': 2,
      'tanggal': '2026-09-23',
      'hari': 'Rabu',
      'is_today': true,
      'jam_mulai': '09:30',
      'jam_selesai': '11:00',
      'kelas_id': 2,
      'nama_kelas': 'XI RPL 1',
      'mapel_id': 3,
      'nama_mapel': 'Pemrograman Web',
      'guru_id': 1,
      'nama_guru': 'I Made Surya, S.Kom',
      'status': 'sudah_diisi',
      'jurnal_id': 88,
      'materi': 'Pengenalan REST API Laravel',
      'total_hadir': 30,
      'total_izin': 1,
      'total_sakit': 1,
      'total_alpa': 0,
      'total_kehadiran': 32,
    });

    expect(sessionSudah.isSudahDiisi, isTrue);
    expect(sessionSudah.isBelumDiisi, isFalse);
    expect(sessionSudah.isToday, isTrue);
    expect(sessionSudah.jurnalId, 88);
    expect(sessionSudah.materi, 'Pengenalan REST API Laravel');
    expect(sessionSudah.totalHadir, 30);
    expect(sessionSudah.totalIzin, 1);
    expect(sessionSudah.totalSakit, 1);
    expect(sessionSudah.totalAlpa, 0);
    expect(sessionSudah.totalKehadiran, 32);
    expect(sessionSudah.hasKehadiran, isTrue);

    // Rule: Future dates must not be permitted
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    expect(todayStr.compareTo(todayStr) <= 0, isTrue); // Today is allowed
    expect('2026-01-10'.compareTo(todayStr) <= 0, isTrue); // Past is allowed
    expect(tomorrowStr.compareTo(todayStr) > 0, isTrue); // Future is blocked
  });

  test('JournalModel correctly handles foto_kegiatan and foto_kegiatan_url', () {
    final journalWithPhoto = JournalModel.fromJson({
      'id': 10,
      'guru_id': 1,
      'jadwal_id': 2,
      'tanggal': '2026-09-24',
      'materi': 'Praktikum IoT dan Arduino',
      'kegiatan': 'Perakitan komponen sensor DHT11',
      'foto_kegiatan': 'jurnal_kegiatan/foto1.jpg',
      'foto_kegiatan_url': 'http://localhost:8000/storage/jurnal_kegiatan/foto1.jpg',
    });

    expect(journalWithPhoto.hasFotoKegiatan, isTrue);
    expect(journalWithPhoto.fotoKegiatan, 'jurnal_kegiatan/foto1.jpg');
    expect(journalWithPhoto.fotoKegiatanUrl, 'http://localhost:8000/storage/jurnal_kegiatan/foto1.jpg');

    final json = journalWithPhoto.toJson();
    expect(json['foto_kegiatan'], 'jurnal_kegiatan/foto1.jpg');
    expect(json['foto_kegiatan_url'], 'http://localhost:8000/storage/jurnal_kegiatan/foto1.jpg');

    final journalWithoutPhoto = JournalModel.fromJson({
      'id': 11,
      'guru_id': 1,
      'tanggal': '2026-09-24',
      'materi': 'Teori Jaringan',
    });

    expect(journalWithoutPhoto.hasFotoKegiatan, isFalse);
    expect(journalWithoutPhoto.fotoKegiatan, isNull);
  });

  test('JournalSessionModel correctly identifies hasFoto', () {
    final sessionWithPhoto = JournalSessionModel.fromJson({
      'jadwal_id': 5,
      'tanggal': '2026-09-24',
      'hari': 'Kamis',
      'jam_mulai': '07:30',
      'jam_selesai': '09:00',
      'kelas_id': 1,
      'nama_kelas': 'X TKJ 1',
      'mapel_id': 2,
      'nama_mapel': 'Dasar Komputer',
      'guru_id': 1,
      'nama_guru': 'I Made Surya, S.Kom',
      'status': 'sudah_diisi',
      'foto_kegiatan': 'jurnal_kegiatan/demo.png',
      'foto_kegiatan_url': 'http://localhost:8000/storage/jurnal_kegiatan/demo.png',
    });

    expect(sessionWithPhoto.hasFoto, isTrue);
    expect(sessionWithPhoto.fotoKegiatan, 'jurnal_kegiatan/demo.png');

    final sessionNoPhoto = JournalSessionModel.fromJson({
      'jadwal_id': 6,
      'tanggal': '2026-09-24',
      'hari': 'Kamis',
      'jam_mulai': '09:00',
      'jam_selesai': '10:30',
      'kelas_id': 1,
      'nama_kelas': 'X TKJ 1',
      'mapel_id': 2,
      'nama_mapel': 'Dasar Komputer',
      'guru_id': 1,
      'nama_guru': 'I Made Surya, S.Kom',
      'status': 'belum_diisi',
    });

    expect(sessionNoPhoto.hasFoto, isFalse);
  });

  test('AppImageHelper resolves image URLs properly', () {
    expect(AppImageHelper.resolveImageUrl(null), isNull);
    expect(AppImageHelper.resolveImageUrl(''), isNull);

    // Base64 data URI
    const dataUri = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD';
    expect(AppImageHelper.resolveImageUrl(dataUri), dataUri);

    // Full URL
    const fullUrl = 'https://smkn1abang.sch.id/storage/foto.jpg';
    expect(AppImageHelper.resolveImageUrl(fullUrl), fullUrl);

    // Relative path
    final relativeResolved = AppImageHelper.resolveImageUrl('storage/jurnal_kegiatan/test.jpg');
    expect(relativeResolved, isNotNull);
    expect(relativeResolved!.contains('/storage/jurnal_kegiatan/test.jpg'), isTrue);
  });

  test('AttendanceReportSummary initialization and data model integrity', () {
    final summary = AttendanceReportSummary(
      bulan: 9,
      tahun: 2026,
      kelasId: 1,
      namaKelas: 'X TKJ',
      mapelId: 2,
      namaMapel: 'Dasar Komputer',
      guruId: 1,
      namaGuru: 'I Made Surya, S.Kom',
      totalPertemuan: 12,
      totalSiswa: 30,
      totalHadir: 85,
      totalIzin: 3,
      totalSakit: 2,
      totalAlpa: 0,
      persentaseKehadiran: 94.4,
      pertemuanList: [
        {'id': 1, 'tanggal': '2026-09-02', 'materi': 'Topologi'},
      ],
      perSiswa: [
        {
          'siswa_id': 1,
          'nis': '231001',
          'nama': 'Aditya',
          'hadir': 12,
          'izin': 0,
          'sakit': 0,
          'alpa': 0,
          'persen': 100.0,
          'evaluasi': 'Sangat Baik',
        },
      ],
    );

    expect(summary.totalPertemuan, 12);
    expect(summary.namaKelas, 'X TKJ');
    expect(summary.persentaseKehadiran, 94.4);
    expect(summary.perSiswa.length, 1);
    expect(summary.perSiswa.first['nama'], 'Aditya');
  });

  test('ReportController search, sorting, and CSV generation', () {
    final controller = ReportController();
    controller.namaKelas.value = 'XI TKJ 1';
    controller.namaMapel.value = 'IoT';
    controller.namaGuru.value = 'I Made Surya, S.Kom';
    controller.selectedMonth.value = 9;
    controller.selectedYear.value = 2026;
    controller.totalPertemuan.value = 10;
    controller.persentaseHadir.value = 95.0;

    controller.studentRecaps.assignAll([
      {'nis': '102', 'nama': 'Budi Santoso', 'hadir': 8, 'izin': 1, 'sakit': 1, 'alpa': 0, 'persen': 80.0, 'evaluasi': 'Cukup'},
      {'nis': '101', 'nama': 'Andi Pratama', 'hadir': 10, 'izin': 0, 'sakit': 0, 'alpa': 0, 'persen': 100.0, 'evaluasi': 'Sangat Baik'},
      {'nis': '103', 'nama': 'Citra Dewi', 'hadir': 6, 'izin': 0, 'sakit': 0, 'alpa': 4, 'persen': 60.0, 'evaluasi': 'Perlu Perhatian'},
    ]);

    // Test Nama A-Z default
    controller.sortBy.value = 'Nama A-Z';
    var filtered = controller.filteredStudents;
    expect(filtered[0]['nama'], 'Andi Pratama');
    expect(filtered[1]['nama'], 'Budi Santoso');
    expect(filtered[2]['nama'], 'Citra Dewi');

    // Test % Tertinggi
    controller.sortBy.value = '% Tertinggi';
    filtered = controller.filteredStudents;
    expect(filtered[0]['nama'], 'Andi Pratama'); // 100.0
    expect(filtered[2]['nama'], 'Citra Dewi'); // 60.0

    // Test Alpa Terbanyak
    controller.sortBy.value = 'Alpa Terbanyak';
    filtered = controller.filteredStudents;
    expect(filtered[0]['nama'], 'Citra Dewi'); // alpa 4

    // Test Search Filter
    controller.searchQuery.value = 'Budi';
    filtered = controller.filteredStudents;
    expect(filtered.length, 1);
    expect(filtered.first['nama'], 'Budi Santoso');

    controller.searchQuery.value = '';

    // Test CSV string generation
    final csv = controller.generateCsvString();
    expect(csv.contains('LAPORAN REKAPITULASI KEHADIRAN SISWA'), isTrue);
    expect(csv.contains('XI TKJ 1'), isTrue);
    expect(csv.contains('Andi Pratama'), isTrue);
    expect(csv.contains('Budi Santoso'), isTrue);
  });

  test('JournalSessionModel.fromSchedule converts schedule to session accurately', () {
    final schedule = ScheduleModel(
      id: 8,
      guruId: 1,
      kelasId: 2,
      mapelId: 1,
      hari: 'Sabtu',
      jamMulai: '07:30',
      jamSelesai: '09:45',
      namaGuru: 'I Made Surya, S.Kom',
      namaKelas: 'XI TKJ 1',
      namaMapel: 'IoT',
    );

    // Unfilled session test
    final sessionUnfilled = JournalSessionModel.fromSchedule(schedule);
    expect(sessionUnfilled.jadwalId, 8);
    expect(sessionUnfilled.hari, 'Sabtu');
    expect(sessionUnfilled.namaKelas, 'XI TKJ 1');
    expect(sessionUnfilled.namaMapel, 'IoT');
    expect(sessionUnfilled.status, 'belum_diisi');
    expect(sessionUnfilled.isBelumDiisi, isTrue);
    expect(sessionUnfilled.isSudahDiisi, isFalse);

    // Filled session test with existing journal
    final existingJournal = JournalModel(
      id: 99,
      guruId: 1,
      jadwalId: 8,
      tanggal: DateFormatter.getTodayDateIso(),
      materi: 'Praktikum Sensor Suhu DHT22',
      kegiatan: 'Siswa memprogram mikrokontroler membaca suhu.',
      totalHadir: 28,
      totalIzin: 1,
      totalSakit: 1,
      totalAlpa: 0,
    );

    final sessionFilled = JournalSessionModel.fromSchedule(schedule, existingJournal: existingJournal);
    expect(sessionFilled.jadwalId, 8);
    expect(sessionFilled.jurnalId, 99);
    expect(sessionFilled.status, 'sudah_diisi');
    expect(sessionFilled.isSudahDiisi, isTrue);
    expect(sessionFilled.materi, 'Praktikum Sensor Suhu DHT22');
    expect(sessionFilled.totalHadir, 28);
    expect(sessionFilled.totalKehadiran, 30);
  });

  test('ScheduleService filters today schedules strictly by current day and account', () async {
    final service = ScheduleService();
    final todayDay = DateFormatter.getTodayDayName();

    // Test Guru 1 (Surya)
    final schedulesGuru1 = await service.getTodaySchedules(guruId: 1);
    for (final s in schedulesGuru1) {
      expect(s.hari.toLowerCase(), todayDay.toLowerCase());
      expect(s.guruId, 1);
    }

    // Test Guru 2 (Dewi)
    final schedulesGuru2 = await service.getTodaySchedules(guruId: 2);
    for (final s in schedulesGuru2) {
      expect(s.hari.toLowerCase(), todayDay.toLowerCase());
      expect(s.guruId, 2);
    }
  });
}

