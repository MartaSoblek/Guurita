<?php

namespace App\Http\Controllers\Api;

use App\Models\Kelas;
use App\Models\Siswa;
use App\Models\Kehadiran;
use App\Models\Jurnal;
use App\Models\MataPelajaran;
use App\Models\User;
use Illuminate\Http\Request;

class LaporanController extends BaseApiController
{
    public function kehadiran(Request $request)
    {
        $bulan = $request->input('bulan', date('n'));
        $tahun = $request->input('tahun', date('Y'));
        $kelasId = $request->input('kelas_id');
        $mapelId = $request->input('mapel_id');
        $guruId = $request->input('guru_id');

        $user = $request->user();
        if ($user && $user->role !== 'admin' && empty($guruId)) {
            $guruId = $user->id;
        }

        // Jika kelas_id belum dispesifikasikan, pilih kelas pertama
        if (!$kelasId) {
            $firstKelas = Kelas::orderBy('id', 'asc')->first();
            $kelasId = $firstKelas ? $firstKelas->id : null;
        }

        $kelas = $kelasId ? Kelas::find($kelasId) : null;
        $mapel = $mapelId ? MataPelajaran::find($mapelId) : null;
        $guru = $guruId ? User::find($guruId) : null;

        // Ambil sesi Jurnal KBM yang sesuai filter
        $jurnalQuery = Jurnal::with(['jadwal.kelas', 'jadwal.mapel', 'guru'])
            ->orderBy('tanggal', 'asc');

        if ($bulan) {
            $jurnalQuery->whereMonth('tanggal', $bulan);
        }
        if ($tahun) {
            $jurnalQuery->whereYear('tanggal', $tahun);
        }
        if ($guruId) {
            $jurnalQuery->where('guru_id', $guruId);
        }
        if ($kelasId) {
            $jurnalQuery->whereHas('jadwal', function ($qj) use ($kelasId) {
                $qj->where('kelas_id', $kelasId);
            });
        }
        if ($mapelId) {
            $jurnalQuery->whereHas('jadwal', function ($qj) use ($mapelId) {
                $qj->where('mapel_id', $mapelId);
            });
        }

        $jurnals = $jurnalQuery->get();
        $jurnalIds = $jurnals->pluck('id');
        $totalPertemuan = $jurnals->count();

        // Ambil daftar siswa di kelas tersebut
        $siswaQuery = Siswa::query()->orderBy('nama', 'asc');
        if ($kelasId) {
            $siswaQuery->where('kelas_id', $kelasId);
        }
        $targetStudents = $siswaQuery->get();

        // Ambil catatan presensi dari jurnal-jurnal tersebut
        $allRecords = Kehadiran::whereIn('jurnal_id', $jurnalIds)->get();

        $totalHadir = $allRecords->where('status', 'Hadir')->count();
        $totalIzin  = $allRecords->where('status', 'Izin')->count();
        $totalSakit = $allRecords->where('status', 'Sakit')->count();
        $totalAlpa  = $allRecords->where('status', 'Alpa')->count();
        $totalCount = $allRecords->count();

        $persenHadir = $totalCount > 0 ? round(($totalHadir / $totalCount) * 100, 1) : 0.0;

        // Rekapitulasi per siswa
        $perSiswa = $targetStudents->map(function ($st) use ($allRecords, $totalPertemuan, $jurnals) {
            $records = $allRecords->where('siswa_id', $st->id);
            $h = $records->where('status', 'Hadir')->count();
            $i = $records->where('status', 'Izin')->count();
            $s = $records->where('status', 'Sakit')->count();
            $a = $records->where('status', 'Alpa')->count();
            $tot = $records->count();

            // Hitung persentase terhadap total pertemuan atau total tercatat
            $baseTotal = $totalPertemuan > 0 ? $totalPertemuan : $tot;
            $persen = $baseTotal > 0 ? round(($h / $baseTotal) * 100, 1) : 0.0;

            // Evaluasi status
            $evaluasi = 'Sangat Baik';
            if ($persen < 75) {
                $evaluasi = 'Perlu Perhatian';
            } elseif ($persen < 85) {
                $evaluasi = 'Cukup';
            } elseif ($persen < 95) {
                $evaluasi = 'Baik';
            }

            // Riwayat status per sesi
            $history = [];
            foreach ($jurnals as $j) {
                $rec = $records->firstWhere('jurnal_id', $j->id);
                $history[] = [
                    'jurnal_id'  => $j->id,
                    'tanggal'    => $j->tanggal,
                    'materi'     => $j->materi,
                    'status'     => $rec ? $rec->status : '-',
                    'keterangan' => $rec ? $rec->keterangan : null,
                ];
            }

            return [
                'siswa_id'        => $st->id,
                'nis'             => $st->nis,
                'nama'            => $st->nama,
                'hadir'           => $h,
                'izin'            => $i,
                'sakit'           => $s,
                'alpa'            => $a,
                'total_tercatat'  => $tot,
                'persen'          => $persen,
                'evaluasi'        => $evaluasi,
                'history'         => $history,
            ];
        });

        // Daftar sesi pertemuan
        $pertemuanList = $jurnals->map(function ($j) {
            return [
                'id'       => $j->id,
                'tanggal'  => $j->tanggal,
                'materi'   => $j->materi,
                'jam'      => optional($j->jadwal)->jam_mulai . ' - ' . optional($j->jadwal)->jam_selesai,
            ];
        });

        return $this->sendResponse([
            'bulan'             => $bulan ? (int) $bulan : null,
            'tahun'             => (int) $tahun,
            'kelas_id'          => $kelasId ? (int) $kelasId : null,
            'nama_kelas'        => $kelas ? $kelas->nama_kelas : 'Semua Kelas',
            'mapel_id'          => $mapelId ? (int) $mapelId : null,
            'nama_mapel'        => $mapel ? $mapel->nama_mapel : 'Semua Mapel',
            'guru_id'           => $guruId ? (int) $guruId : null,
            'nama_guru'         => $guru ? $guru->nama : ($user ? $user->nama : 'Semua Guru'),
            'total_pertemuan'   => $totalPertemuan,
            'total_siswa'       => $targetStudents->count(),
            'total_hadir'       => $totalHadir,
            'total_izin'        => $totalIzin,
            'total_sakit'       => $totalSakit,
            'total_alpa'        => $totalAlpa,
            'persentase_hadir'  => $persenHadir,
            'pertemuan_list'    => $pertemuanList,
            'per_siswa'         => $perSiswa,
        ], 'Laporan rekapitulasi kehadiran');
    }

    public function jurnal(Request $request)
    {
        $user = $request->user();
        $isAdmin = ($user->role === 'admin');

        $query = Jurnal::with(['guru', 'jadwal.kelas', 'jadwal.mapel'])
            ->orderBy('tanggal', 'desc');

        if ($isAdmin) {
            if ($request->filled('guru_id')) {
                $query->where('guru_id', $request->guru_id);
            }
        } else {
            $query->where('guru_id', $user->id);
        }

        $jurnals = $query->get();

        return $this->sendResponse($jurnals, 'Laporan aktivitas jurnal');
    }
}
