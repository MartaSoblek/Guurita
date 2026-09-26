<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\JadwalController;
use App\Http\Controllers\Api\KelasController;
use App\Http\Controllers\Api\MataPelajaranController;
use App\Http\Controllers\Api\JurnalController;
use App\Http\Controllers\Api\KehadiranController;
use App\Http\Controllers\Api\LaporanController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\SiswaController;
use App\Http\Controllers\Api\GuruController;

/*
|--------------------------------------------------------------------------
| GURITA REST API Routes - SMK 1 Abang
|--------------------------------------------------------------------------
*/

// Public Authentication Route
Route::post('/login', [AuthController::class, 'login']);

// Protected Routes (auth:sanctum)
Route::middleware('auth:sanctum')->group(function () {
    // Auth & Profile
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/profile', [AuthController::class, 'profile']);
    Route::put('/profile', [ProfileController::class, 'update']);

    // Kelola Data Guru (Admin & Guru List)
    Route::get('/guru', [GuruController::class, 'index']);
    Route::post('/guru', [GuruController::class, 'store']);
    Route::get('/guru/{id}', [GuruController::class, 'show']);
    Route::put('/guru/{id}', [GuruController::class, 'update']);
    Route::delete('/guru/{id}', [GuruController::class, 'destroy']);
    Route::post('/guru/{id}/impersonate', [GuruController::class, 'impersonate']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // Jadwal Mengajar
    Route::get('/jadwal', [JadwalController::class, 'index']);
    Route::get('/jadwal/hari-ini', [JadwalController::class, 'hariIni']);
    Route::post('/jadwal', [JadwalController::class, 'store']);
    Route::get('/jadwal/{id}', [JadwalController::class, 'show']);
    Route::put('/jadwal/{id}', [JadwalController::class, 'update']);
    Route::delete('/jadwal/{id}', [JadwalController::class, 'destroy']);

    // Kelas & Siswa
    Route::get('/kelas', [KelasController::class, 'index']);
    Route::post('/kelas', [KelasController::class, 'store']);
    Route::get('/kelas/{id}', [KelasController::class, 'show']);
    Route::put('/kelas/{id}', [KelasController::class, 'update']);
    Route::delete('/kelas/{id}', [KelasController::class, 'destroy']);
    Route::get('/kelas/{id}/siswa', [KelasController::class, 'siswa']);

    // Siswa (CRUD Master Data Siswa & Import Excel)
    Route::get('/siswa', [SiswaController::class, 'index']);
    Route::get('/siswa/template', [SiswaController::class, 'template']);
    Route::get('/siswa/template/excel', [SiswaController::class, 'template']);
    Route::post('/siswa/import', [SiswaController::class, 'import']);
    Route::post('/siswa', [SiswaController::class, 'store']);
    Route::get('/siswa/{id}', [SiswaController::class, 'show']);
    Route::put('/siswa/{id}', [SiswaController::class, 'update']);
    Route::delete('/siswa/{id}', [SiswaController::class, 'destroy']);

    // Mata Pelajaran
    Route::get('/mapel', [MataPelajaranController::class, 'index']);
    Route::post('/mapel', [MataPelajaranController::class, 'store']);
    Route::get('/mapel/{id}', [MataPelajaranController::class, 'show']);
    Route::put('/mapel/{id}', [MataPelajaranController::class, 'update']);
    Route::delete('/mapel/{id}', [MataPelajaranController::class, 'destroy']);

    // Jurnal Mengajar
    Route::get('/jurnal', [JurnalController::class, 'index']);
    Route::get('/jurnal/sesi-semester', [JurnalController::class, 'sesiSemester']);
    Route::post('/jurnal', [JurnalController::class, 'store']);
    Route::get('/jurnal/{id}', [JurnalController::class, 'show']);
    Route::match(['put', 'post'], '/jurnal/{id}', [JurnalController::class, 'update']);
    Route::delete('/jurnal/{id}', [JurnalController::class, 'destroy']);

    // Kehadiran Siswa
    Route::get('/jurnal/{jurnal}/kehadiran', [KehadiranController::class, 'byJurnal']);
    Route::post('/jurnal/{jurnal}/kehadiran', [KehadiranController::class, 'storeOrUpdateBatch']);
    Route::put('/kehadiran/{id}', [KehadiranController::class, 'update']);

    // Laporan
    Route::get('/laporan/kehadiran', [LaporanController::class, 'kehadiran']);
    Route::get('/laporan/jurnal', [LaporanController::class, 'jurnal']);
});
