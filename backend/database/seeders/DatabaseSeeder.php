<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Kelas;
use App\Models\Siswa;
use App\Models\MataPelajaran;
use App\Models\Jadwal;
use App\Models\Jurnal;
use App\Models\Kehadiran;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // 1. Seed Users (1 Admin & 2 Teachers)
        $admin = User::create([
            'nama' => 'Administrator',
            'nip' => '197901012003121002',
            'email' => 'admin@smkn1abang.sch.id',
            'password' => Hash::make('password'),
            'role' => 'admin',
            'mata_pelajaran' => 'Semua Mata Pelajaran',
        ]);

        $guru1 = User::create([
            'nama' => 'I Made Surya, S.Kom',
            'nip' => '198507122010011008',
            'email' => 'surya@smkn1abang.sch.id',
            'password' => Hash::make('password'),
            'role' => 'guru',
            'mata_pelajaran' => 'IoT & Dasar Komputer',
        ]);

        $guru2 = User::create([
            'nama' => 'Ni Luh Dewi, S.Pd',
            'nip' => '198904252014022003',
            'email' => 'dewi@smkn1abang.sch.id',
            'password' => Hash::make('password'),
            'role' => 'guru',
            'mata_pelajaran' => 'Administrasi Infrastruktur Jaringan',
        ]);

        // 2. Seed Kelas (3 Classes)
        $kelas1 = Kelas::create(['nama_kelas' => 'X TKJ', 'tingkat' => 'X']);
        $kelas2 = Kelas::create(['nama_kelas' => 'XI TKJ 1', 'tingkat' => 'XI']);
        $kelas3 = Kelas::create(['nama_kelas' => 'XI TKJ 2', 'tingkat' => 'XI']);

        // 3. Seed Mata Pelajaran (3 Subjects)
        $mapel1 = MataPelajaran::create(['kode_mapel' => 'IOT-01', 'nama_mapel' => 'IoT']);
        $mapel2 = MataPelajaran::create(['kode_mapel' => 'DSK-02', 'nama_mapel' => 'Dasar Komputer']);
        $mapel3 = MataPelajaran::create(['kode_mapel' => 'AIJ-03', 'nama_mapel' => 'Administrasi Infrastruktur Jaringan']);

        // 4. Seed Siswa (30 students per class = 90 students)
        $firstNames = [
            'I Wayan', 'I Made', 'I Nyoman', 'I Ketut', 'Ni Wayan',
            'Ni Made', 'Ni Nyoman', 'Ni Ketut', 'Kadek', 'Komang',
            'Gede', 'Putu', 'Anak Agung', 'Ida Bagus', 'Desak',
            'Agus', 'Budi', 'Rizky', 'Dian', 'Siti',
            'Ahmad', 'Dimas', 'Eka', 'Bayu', 'Mega',
            'Satria', 'Wira', 'Lestari', 'Pradnya', 'Widya'
        ];
        $lastNames = [
            'Artana', 'Sudarsana', 'Suartika', 'Widiarta', 'Wiguna',
            'Pratama', 'Saputra', 'Adnyana', 'Kusuma', 'Mahendra',
            'Gunawan', 'Wijaya', 'Santosa', 'Darmo', 'Setiawan',
            'Hidayat', 'Nugraha', 'Permana', 'Laksana', 'Kencana',
            'Utama', 'Suryani', 'Indrawan', 'Baskara', 'Purnomo',
            'Yasa', 'Astawa', 'Mahardika', 'Dharmawan', 'Sucipto'
        ];

        $allClasses = [$kelas1, $kelas2, $kelas3];
        $createdStudents = [];
        $nisCounter = 1;

        foreach ($allClasses as $clsIndex => $cls) {
            for ($i = 0; $i < 30; $i++) {
                $nis = ($cls->tingkat == 'X' ? '24' : '23') . str_pad($nisCounter, 4, '0', STR_PAD_LEFT);
                $nisn = '008' . str_pad(8000000 + $nisCounter, 7, '0', STR_PAD_LEFT);
                $name = $firstNames[$i % count($firstNames)] . ' ' . $lastNames[($i + $clsIndex * 5) % count($lastNames)];

                $siswa = Siswa::create([
                    'nis' => $nis,
                    'nisn' => $nisn,
                    'nama' => $name,
                    'kelas_id' => $cls->id,
                ]);

                $createdStudents[$cls->id][] = $siswa;
                $nisCounter++;
            }
        }

        // 5. Seed Jadwal
        $j1 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas2->id,
            'mapel_id' => $mapel1->id,
            'hari' => 'Senin',
            'jam_mulai' => '07:30:00',
            'jam_selesai' => '09:00:00',
        ]);

        $j2 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas3->id,
            'mapel_id' => $mapel1->id,
            'hari' => 'Senin',
            'jam_mulai' => '09:15:00',
            'jam_selesai' => '11:45:00',
        ]);

        $j3 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas1->id,
            'mapel_id' => $mapel2->id,
            'hari' => 'Selasa',
            'jam_mulai' => '08:00:00',
            'jam_selesai' => '10:15:00',
        ]);

        $j4 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas2->id,
            'mapel_id' => $mapel1->id,
            'hari' => 'Rabu',
            'jam_mulai' => '07:30:00',
            'jam_selesai' => '09:45:00',
        ]);

        $j5 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas3->id,
            'mapel_id' => $mapel1->id,
            'hari' => 'Rabu',
            'jam_mulai' => '10:00:00',
            'jam_selesai' => '12:15:00',
        ]);

        $j6 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas1->id,
            'mapel_id' => $mapel2->id,
            'hari' => 'Kamis',
            'jam_mulai' => '07:30:00',
            'jam_selesai' => '09:45:00',
        ]);

        $j7 = Jadwal::create([
            'guru_id' => $guru2->id,
            'kelas_id' => $kelas2->id,
            'mapel_id' => $mapel3->id,
            'hari' => 'Jumat',
            'jam_mulai' => '07:30:00',
            'jam_selesai' => '10:00:00',
        ]);

        $j8 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas2->id,
            'mapel_id' => $mapel1->id,
            'hari' => 'Sabtu',
            'jam_mulai' => '07:30:00',
            'jam_selesai' => '09:45:00',
        ]);

        $j9 = Jadwal::create([
            'guru_id' => $guru1->id,
            'kelas_id' => $kelas3->id,
            'mapel_id' => $mapel1->id,
            'hari' => 'Sabtu',
            'jam_mulai' => '10:00:00',
            'jam_selesai' => '12:15:00',
        ]);

        $j10 = Jadwal::create([
            'guru_id' => $guru2->id,
            'kelas_id' => $kelas1->id,
            'mapel_id' => $mapel3->id,
            'hari' => 'Sabtu',
            'jam_mulai' => '08:00:00',
            'jam_selesai' => '10:30:00',
        ]);

        $j11 = Jadwal::create([
            'guru_id' => $guru2->id,
            'kelas_id' => $kelas3->id,
            'mapel_id' => $mapel3->id,
            'hari' => 'Senin',
            'jam_mulai' => '10:00:00',
            'jam_selesai' => '12:00:00',
        ]);

        $j12 = Jadwal::create([
            'guru_id' => $guru2->id,
            'kelas_id' => $kelas1->id,
            'mapel_id' => $mapel3->id,
            'hari' => 'Rabu',
            'jam_mulai' => '08:00:00',
            'jam_selesai' => '10:00:00',
        ]);

        $j13 = Jadwal::create([
            'guru_id' => $guru2->id,
            'kelas_id' => $kelas2->id,
            'mapel_id' => $mapel3->id,
            'hari' => 'Kamis',
            'jam_mulai' => '10:00:00',
            'jam_selesai' => '12:00:00',
        ]);

        // 6. Seed Jurnal
        $jur1 = Jurnal::create([
            'guru_id' => $guru1->id,
            'jadwal_id' => $j1->id,
            'tanggal' => '2026-09-21',
            'materi' => 'Pengenalan Sensor ESP32 dan Arsitektur IoT',
            'kegiatan' => 'Penyampaian materi arsitektur IoT dan pengenalan pinout ESP32, dilanjutkan praktik instalasi board pada Arduino IDE.',
            'metode' => 'Demonstrasi dan Praktikum Terbimbing',
            'media' => 'Modul ESP32, Breadboard, LCD Proyektor',
            'kendala' => 'Dua modul kabel data USB mengalami gangguan koneksi ke laptop siswa.',
            'tindak_lanjut' => 'Mengganti kabel data cadangan dari laboratorium TKJ.',
            'catatan' => 'Seluruh siswa antusias mengikuti praktikum dasar GPIO.',
        ]);

        $jur2 = Jurnal::create([
            'guru_id' => $guru1->id,
            'jadwal_id' => $j2->id,
            'tanggal' => '2026-09-21',
            'materi' => 'Protokol Komunikasi MQTT pada Sistem IoT',
            'kegiatan' => 'Pengujian publish dan subscribe topik sensor suhu menggunakan broker publik HiveMQ.',
            'metode' => 'Studi Kasus & Lab Hands-on',
            'media' => 'ESP32 NodeMCU, Sensor DHT22, Wi-Fi Sekolah',
            'kendala' => 'Trafik Wi-Fi sempat melambat di awal sesi.',
            'tindak_lanjut' => 'Membagi koneksi ke hotspot access point lab TKJ.',
            'catatan' => 'Semua kelompok berhasil menampilkan data di dashboard MQTT.',
        ]);

        $jur3 = Jurnal::create([
            'guru_id' => $guru1->id,
            'jadwal_id' => $j3->id,
            'tanggal' => '2026-09-22',
            'materi' => 'Arsitektur Von Neumann dan Komponen Motherboard',
            'kegiatan' => 'Identifikasi fisik komponen CPU, RAM, Slot PCIe, dan Chipset pada unit PC praktik.',
            'metode' => 'Diskusi Kelompok & Praktik Bongkar Pasang',
            'media' => 'Toolkit Obeng, Motherboard Trainer, Antistatik',
            'kendala' => 'Tidak ada kendala berarti.',
            'tindak_lanjut' => 'Persiapan materi modul power supply untuk pekan depan.',
            'catatan' => 'Siswa kelas X sangat tertib mematuhi SOP K3 kelistrikan.',
        ]);

        // 7. Seed Kehadiran for Jurnal 1 (30 students of XI TKJ 1)
        foreach ($createdStudents[$kelas2->id] as $idx => $st) {
            $status = 'Hadir';
            $ket = null;
            if ($idx == 5) {
                $status = 'Izin';
                $ket = 'Izin acara keluarga';
            } elseif ($idx == 12) {
                $status = 'Sakit';
                $ket = 'Surat dokter terlampir';
            }

            Kehadiran::create([
                'jurnal_id' => $jur1->id,
                'siswa_id' => $st->id,
                'status' => $status,
                'keterangan' => $ket,
            ]);
        }

        // Seed Kehadiran for Jurnal 2 (30 students of XI TKJ 2)
        foreach ($createdStudents[$kelas3->id] as $idx => $st) {
            $status = 'Hadir';
            $ket = null;
            if ($idx == 8) {
                $status = 'Izin';
                $ket = 'Mengikuti lomba olimpiade';
            }

            Kehadiran::create([
                'jurnal_id' => $jur2->id,
                'siswa_id' => $st->id,
                'status' => $status,
                'keterangan' => $ket,
            ]);
        }

        // Seed Kehadiran for Jurnal 3 (30 students of X TKJ)
        foreach ($createdStudents[$kelas1->id] as $st) {
            Kehadiran::create([
                'jurnal_id' => $jur3->id,
                'siswa_id' => $st->id,
                'status' => 'Hadir',
                'keterangan' => null,
            ]);
        }
    }
}
