@echo off
chcp 65001 >nul
title GURITA - Backend Server (Laravel API)
color 0B

echo ==============================================================
echo           GURITA - Gerbang Utama Informasi Sekolah
echo                Backend API Server (Laravel)
echo ==============================================================
echo.

:: 1. Deteksi direktori project dan masuk ke folder backend
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%artisan" (
    cd /d "%SCRIPT_DIR%"
) else if exist "%SCRIPT_DIR%backend\artisan" (
    cd /d "%SCRIPT_DIR%backend"
) else (
    color 0C
    echo [ERROR] File artisan backend tidak ditemukan!
    echo Pastikan file bat ini berada di folder root 'gurita' atau di folder 'backend'.
    echo.
    pause
    exit /b 1
)

:: 2. Deteksi PHP (Cek PATH sistem atau default XAMPP)
where php >nul 2>&1
if %ERRORLEVEL% neq 0 (
    if exist "C:\xampp\php\php.exe" (
        set "PATH=C:\xampp\php;%PATH%"
        echo [OK] PHP ditemukan di C:\xampp\php
    ) else if exist "D:\xampp\php\php.exe" (
        set "PATH=D:\xampp\php;%PATH%"
        echo [OK] PHP ditemukan di D:\xampp\php
    ) else (
        color 0C
        echo [ERROR] PHP tidak ditemukan di sistem maupun instalasi XAMPP default!
        echo Pastikan PHP sudah terinstal dan terdaftar di Environment Variables.
        echo.
        pause
        exit /b 1
    )
)

:: 3. Cek file .env
if not exist ".env" (
    if exist ".env.example" (
        echo [INFO] File .env tidak ditemukan. Menyalin dari .env.example...
        copy ".env.example" ".env" >nul
        php artisan key:generate
        echo [OK] File .env dan APP_KEY berhasil dibuat.
    )
)

:: 4. Cek apakah MySQL berjalan
tasklist /FI "IMAGENAME eq mysqld.exe" 2>nul | findstr /I "mysqld.exe" >nul
if %ERRORLEVEL% neq 0 (
    echo [INFO] MySQL belum aktif. Mencoba menyalakan MySQL XAMPP...
    if exist "C:\xampp\mysql_start.bat" (
        start "" /min "C:\xampp\mysql_start.bat"
        ping 127.0.0.1 -n 3 >nul
        echo [OK] Layanan MySQL XAMPP telah dipicu untuk berjalan.
    ) else (
        echo [CATATAN] Pastikan MySQL telah diaktifkan di XAMPP Control Panel.
    )
) else (
    echo [OK] Layanan MySQL terdeteksi aktif.
)

:: 5. Informasi URL Server
echo.
echo ==============================================================
echo  Server API siap dijalankan!
echo  - Host / Port : http://127.0.0.1:8000
echo  - API Base URL: http://localhost:8000/api
echo  - Android Emu : http://10.0.2.2:8000/api
echo ==============================================================
echo  Tekan Ctrl + C di jendela ini untuk menghentikan server.
echo ==============================================================
echo.

:: 6. Jalankan Server Laravel
php artisan serve --host=0.0.0.0 --port=8000

:: 7. Jika server berhenti
echo.
echo [INFO] Server backend telah dihentikan.
pause
