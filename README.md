# GURITA — Gerbang Utama Informasi Sekolah
### SMK 1 Abang

**GURITA** adalah aplikasi digital sekolah yang dikembangkan menggunakan **satu codebase Flutter** untuk **Mobile Android** (Smartphone & Tablet) serta **Web Browser / Desktop**, terintegrasi penuh dengan **Laravel REST API** dan basis data **MySQL**.

Aplikasi ini dirancang khusus untuk mempermudah guru di **SMK 1 Abang** dalam mengelola:
* Jurnal kegiatan mengajar harian (KBM)
* Presensi kehadiran siswa per jam pelajaran dengan fitur 1-klik "Hadir Semua"
* Jadwal mengajar mingguan dan harian
* Rekapitulasi aktivitas pembelajaran dan statistik kehadiran

---

## 🏛️ Arsitektur Sistem

```text
                    GURITA
        Gerbang Utama Informasi Sekolah
                    │
          ┌─────────┴─────────┐
          │                   │
          ▼                   ▼
     Flutter Mobile      Flutter Web
     (Android/Tablet)   (Chrome/Edge)
          │                   │
          └─────────┬─────────┘
                    │
                REST API
             (Bearer Sanctum)
                    │
                    ▼
                 Laravel
                    │
                    ▼
                  MySQL
               (MariaDB)
```

> **Catatan Arsitektur:**
> * Satu codebase Flutter (`frontend/`) melayani Mobile dan Web secara adaptif.
> * Flutter tidak mengakses MySQL secara langsung; seluruh komunikasi database melalui Laravel REST API.
> * Responsif menggunakan `ResponsiveLayout`:
>   * **Mobile (< 600px)**: Bottom Navigation Bar, single column, full-width touch-friendly cards.
>   * **Tablet (600 - 1024px)**: Layout adaptable dengan multi-card views.
>   * **Web/Desktop (> 1024px)**: Collapsible Sidebar, Header TopBar, data table dengan pagination, multi-column dashboard, 2-kolom form dengan batas lebar kontainer (`maxContentWidth`).

---

## 🎨 Tema & Desain UI/UX

Menggunakan Material 3 dengan identitas visual resmi:
* **Primary Color**: `#2563EB` (Royal Blue)
* **Background**: `#F8FAFC` (Slate Light)
* **Card**: `#FFFFFF`
* **Text Main**: `#1E293B`
* **Text Muted**: `#64748B`
* **Success**: `#22C55E`
* **Warning**: `#F59E0B`
* **Error**: `#EF4444`

---

## 📁 Struktur Direktori Proyek

```text
gurita/
├── frontend/                     # Satu Codebase Flutter (Mobile & Web)
│   ├── lib/
│   │   ├── main.dart             # Entry point & GetX / GetStorage init
│   │   ├── app/
│   │   │   ├── constants/        # AppColors, AppConstants
│   │   │   ├── responsive/       # ResponsiveLayout, Breakpoints, Container
│   │   │   ├── routes/           # AppRoutes, AppPages
│   │   │   └── theme/            # Material 3 AppTheme
│   │   ├── core/
│   │   │   ├── network/          # DioClient (interceptor, token, timeout)
│   │   │   ├── utils/            # DateFormatter (Bahasa Indonesia), AlertHelper
│   │   │   └── widgets/          # GuritaLogo, Sidebar, Header, MetricCard, dll
│   │   ├── data/
│   │   │   ├── models/           # User, Class, Student, Subject, Schedule, Journal, Attendance
│   │   │   ├── providers/        # DummyDataProvider (SMK 1 Abang)
│   │   │   └── services/         # Api, Auth, Schedule, Journal, Attendance, Report, Profile
│   │   └── modules/              # Clean GetX Architecture (Controllers & Views)
│   │       ├── splash/           # Splash screen dengan logo GURITA
│   │       ├── auth/             # Login responsif
│   │       ├── main_navigation/  # Shell adaptif (Sidebar web & Bottom nav mobile)
│   │       ├── dashboard/        # Dashboard metrik & jadwal hari ini
│   │       ├── schedule/         # Jadwal mengajar mingguan & filter hari
│   │       ├── attendance/       # Presensi siswa + Hadir Semua + Live counter
│   │       ├── journal/          # Form KBM 2 kolom + Riwayat Jurnal + Detail
│   │       ├── report/           # Rekap kehadiran bulanan + tabel siswa
│   │       └── profile/          # Profil guru, ubah data, ubah password, logout
│   └── test/
│       └── widget_test.dart      # Pengujian komponen frontend
│
└── backend/                      # Laravel REST API
    ├── app/
    │   ├── Http/
    │   │   ├── Controllers/Api/  # Auth, Dashboard, Jadwal, Jurnal, Kehadiran, Laporan, Profile
    │   │   └── Requests/         # Form Requests & validasi JSON
    │   └── Models/               # User, Kelas, Siswa, MataPelajaran, Jadwal, Jurnal, Kehadiran
    ├── database/
    │   ├── migrations/           # 7 Migrasi tabel lengkap dengan FK & constraint
    │   └── seeders/              # Seeder SMK 1 Abang (2 guru, 3 kelas, 90 siswa, 7 jadwal, dll)
    ├── routes/
    │   └── api.php               # 22 REST API endpoints terproteksi Sanctum
    └── tests/
        └── Feature/              # Pengujian unit & fitur endpoint Laravel
```

---

## 🔑 Akun Uji Coba (Demo Credentials)

| Peran | Nama Guru | Email | Password | Mata Pelajaran |
|---|---|---|---|---|
| **Guru 1** | I Made Surya, S.Kom | `surya@smkn1abang.sch.id` | `password` | IoT & Dasar Komputer |
| **Guru 2** | Ni Luh Dewi, S.Pd | `dewi@smkn1abang.sch.id` | `password` | Administrasi Infrastruktur Jaringan |

---

## 🚀 Panduan Menjalankan Sistem

### 1. Menjalankan Backend Laravel
Masuk ke direktori `backend/`:
```bash
cd backend
# Jalankan migrasi dan seeder data dummy SMK 1 Abang
php artisan migrate:fresh --seed

# Jalankan test suite backend
php artisan test

# Jalankan server REST API Laravel
php artisan serve
```
> Server akan berjalan di: `http://localhost:8000/api`

---

### 2. Menjalankan Frontend Flutter

Masuk ke direktori `frontend/`:
```bash
cd frontend

# Jalankan analisis kode (0 errors / 0 warnings)
flutter analyze

# Jalankan pengujian widget
flutter test
```

#### Menjalankan di Web Browser (Chrome/Edge):
```bash
flutter run -d chrome
```

#### Menjalankan di Mobile Android (Device / Emulator):
```bash
flutter run
```

#### Membangun Output Produksi Web:
```bash
flutter build web --no-tree-shake-icons
```
Hasil build web tersedia pada direktori `frontend/build/web`.

---

## 📡 Ringkasan Endpoint REST API

| Method | Endpoint | Keterangan |
|---|---|---|
| `POST` | `/api/login` | Autentikasi guru & generate token Sanctum |
| `POST` | `/api/logout` | Revoke token aktif user |
| `GET` | `/api/profile` | Data profil guru yang sedang login |
| `PUT` | `/api/profile` | Update nama, email, dan kata sandi |
| `GET` | `/api/dashboard` | Statistik metrik dan jadwal hari ini |
| `GET` | `/api/jadwal` | Seluruh jadwal guru |
| `GET` | `/api/jadwal/hari-ini` | Jadwal mengajar hari ini |
| `GET` | `/api/jadwal/{id}` | Detail satu jadwal mengajar |
| `GET` | `/api/kelas` | Daftar kelas beserta jumlah siswa |
| `GET` | `/api/kelas/{id}/siswa` | Daftar siswa dalam suatu kelas |
| `GET` | `/api/mapel` | Daftar mata pelajaran |
| `GET` | `/api/jurnal` | Riwayat jurnal (pencarian & filter tanggal/kelas/mapel) |
| `POST` | `/api/jurnal` | Tambah jurnal baru beserta data presensi siswa |
| `GET` | `/api/jurnal/{id}` | Detail lengkap jurnal & rekap presensi |
| `PUT` | `/api/jurnal/{id}` | Update data jurnal mengajar |
| `DELETE` | `/api/jurnal/{id}` | Hapus data jurnal |
| `GET` | `/api/jurnal/{jurnal}/kehadiran` | Ambil presensi siswa per sesi jurnal |
| `POST` | `/api/jurnal/{jurnal}/kehadiran` | Simpan/update massal presensi siswa |
| `PUT` | `/api/kehadiran/{id}` | Update status presensi 1 siswa |
| `GET` | `/api/laporan/kehadiran` | Rekapitulasi absensi bulanan |
| `GET` | `/api/laporan/jurnal` | Rekapitulasi aktivitas KBM |

---

## 🏫 Hak Cipta & Branding
Aplikasi **GURITA** (Gerbang Utama Informasi Sekolah) dikembangkan khusus untuk civitas akademika **SMK 1 Abang**.
