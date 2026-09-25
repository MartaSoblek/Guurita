<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\JurnalStoreRequest;
use App\Models\Jurnal;
use App\Models\Kehadiran;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class JurnalController extends BaseApiController
{
    public function index(Request $request)
    {
        $user = $request->user();
        $isAdmin = ($user->role === 'admin');

        $query = Jurnal::with(['guru', 'jadwal.kelas', 'jadwal.mapel']);

        if ($isAdmin) {
            if ($request->filled('guru_id')) {
                $query->where('guru_id', $request->guru_id);
            }
        } else {
            $query->where('guru_id', $user->id);
        }

        // Filter search
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('materi', 'like', "%{$search}%")
                  ->orWhere('kegiatan', 'like', "%{$search}%")
                  ->orWhereHas('guru', function ($qg) use ($search) {
                      $qg->where('nama', 'like', "%{$search}%");
                  })
                  ->orWhereHas('jadwal.kelas', function ($qk) use ($search) {
                      $qk->where('nama_kelas', 'like', "%{$search}%");
                  })
                  ->orWhereHas('jadwal.mapel', function ($qm) use ($search) {
                      $qm->where('nama_mapel', 'like', "%{$search}%");
                  });
            });
        }

        // Filter tanggal
        if ($request->filled('tanggal')) {
            $query->where('tanggal', $request->tanggal);
        }

        // Filter kelas
        if ($request->filled('kelas_id')) {
            $query->whereHas('jadwal', function ($q) use ($request) {
                $q->where('kelas_id', $request->kelas_id);
            });
        }

        // Filter mapel
        if ($request->filled('mapel_id')) {
            $query->whereHas('jadwal', function ($q) use ($request) {
                $q->where('mapel_id', $request->mapel_id);
            });
        }

        $jurnalList = $query->orderBy('tanggal', 'desc')->orderBy('id', 'desc')->get();

        // Calculate attendance summary per journal
        $data = $jurnalList->map(function ($jurnal) {
            $hadir = Kehadiran::where('jurnal_id', $jurnal->id)->where('status', 'Hadir')->count();
            $izin  = Kehadiran::where('jurnal_id', $jurnal->id)->where('status', 'Izin')->count();
            $sakit = Kehadiran::where('jurnal_id', $jurnal->id)->where('status', 'Sakit')->count();
            $alpa  = Kehadiran::where('jurnal_id', $jurnal->id)->where('status', 'Alpa')->count();

            $arr = $jurnal->toArray();
            $arr['total_hadir'] = $hadir;
            $arr['total_izin']  = $izin;
            $arr['total_sakit'] = $sakit;
            $arr['total_alpa']  = $alpa;
            $arr['nama_guru']   = $jurnal->guru ? $jurnal->guru->nama : null;
            $arr['nama_kelas']  = $jurnal->jadwal ? $jurnal->jadwal->kelas->nama_kelas : null;
            $arr['nama_mapel']  = $jurnal->jadwal ? $jurnal->jadwal->mapel->nama_mapel : null;
            $arr['jam_mulai']   = $jurnal->jadwal ? substr($jurnal->jadwal->jam_mulai, 0, 5) : null;
            $arr['jam_selesai'] = $jurnal->jadwal ? substr($jurnal->jadwal->jam_selesai, 0, 5) : null;

            return $arr;
        });

        return $this->sendResponse($data, 'Riwayat jurnal mengajar');
    }

    public function sesiSemester(Request $request)
    {
        $user = $request->user();
        $isAdmin = ($user->role === 'admin');

        $guruId = null;
        if ($isAdmin) {
            if ($request->filled('guru_id')) {
                $guruId = $request->guru_id;
            }
        } else {
            $guruId = $user->id;
        }

        // Tentukan semester aktif
        $today = date('Y-m-d');
        $currentMonth = (int)date('n');
        $currentYear = (int)date('Y');

        if ($currentMonth >= 7) {
            $startDate = "{$currentYear}-07-01";
            $semesterName = "Semester Ganjil {$currentYear}/" . ($currentYear + 1);
        } else {
            $startDate = "{$currentYear}-01-01";
            $semesterName = "Semester Genap " . ($currentYear - 1) . "/{$currentYear}";
        }

        // Tanggal yang belum dilewati TIDAK MUNCUL (maksimal hari ini)
        $endDate = $today;

        // Ambil data jadwal
        $jadwalQuery = \App\Models\Jadwal::with(['kelas', 'mapel', 'guru']);
        if ($guruId) {
            $jadwalQuery->where('guru_id', $guruId);
        }
        if ($request->filled('kelas_id')) {
            $jadwalQuery->where('kelas_id', $request->kelas_id);
        }
        $jadwalList = $jadwalQuery->get();

        // Kelompokkan jadwal berdasarkan hari
        $jadwalByHari = [];
        foreach ($jadwalList as $j) {
            $hariNorm = ucfirst(strtolower(trim($j->hari)));
            $jadwalByHari[$hariNorm][] = $j;
        }

        // Mapping hari dalam bahasa Indonesia (0 = Minggu, 1 = Senin, ...)
        $dayMap = [
            0 => 'Minggu',
            1 => 'Senin',
            2 => 'Selasa',
            3 => 'Rabu',
            4 => 'Kamis',
            5 => 'Jumat',
            6 => 'Sabtu',
        ];

        // Ambil data jurnal yang sudah ada pada rentang semester hingga hari ini
        $jurnalQuery = Jurnal::whereBetween('tanggal', [$startDate, $endDate]);
        if ($guruId) {
            $jurnalQuery->where('guru_id', $guruId);
        }
        $existingJurnals = $jurnalQuery->get()->keyBy(function ($item) {
            return ($item->jadwal_id ?? 0) . '_' . $item->tanggal;
        });

        // Pre-aggregate data kehadiran untuk semua jurnal pada rentang ini
        $jurnalIds = $existingJurnals->pluck('id')->filter()->all();
        $kehadiranByJurnal = [];
        if (!empty($jurnalIds)) {
            $kehadiranStats = Kehadiran::whereIn('jurnal_id', $jurnalIds)
                ->select('jurnal_id', 'status', DB::raw('count(*) as total'))
                ->groupBy('jurnal_id', 'status')
                ->get();
            foreach ($kehadiranStats as $ks) {
                $kehadiranByJurnal[$ks->jurnal_id][$ks->status] = (int)$ks->total;
            }
        }

        $sessions = [];
        $currentTimestamp = strtotime($endDate);
        $startTimestamp = strtotime($startDate);

        // Iterasi mundur dari hari ini ke awal semester (agar urutan terbaru berada di paling atas)
        while ($currentTimestamp >= $startTimestamp) {
            $dateStr = date('Y-m-d', $currentTimestamp);
            $dayOfWeek = (int)date('w', $currentTimestamp);
            $dayName = $dayMap[$dayOfWeek] ?? '';

            if (isset($jadwalByHari[$dayName])) {
                foreach ($jadwalByHari[$dayName] as $jadwal) {
                    $key = $jadwal->id . '_' . $dateStr;
                    $jurnal = $existingJurnals->get($key);

                    $isFilled = ($jurnal !== null);
                    $status = $isFilled ? 'sudah_diisi' : 'belum_diisi';

                    $hadir = 0; $izin = 0; $sakit = 0; $alpa = 0;
                    if ($isFilled && isset($kehadiranByJurnal[$jurnal->id])) {
                        $hadir = $kehadiranByJurnal[$jurnal->id]['Hadir'] ?? 0;
                        $izin  = $kehadiranByJurnal[$jurnal->id]['Izin'] ?? 0;
                        $sakit = $kehadiranByJurnal[$jurnal->id]['Sakit'] ?? 0;
                        $alpa  = $kehadiranByJurnal[$jurnal->id]['Alpa'] ?? 0;
                    }
                    $totalKehadiran = $hadir + $izin + $sakit + $alpa;

                    $sessions[] = [
                        'jadwal_id' => $jadwal->id,
                        'tanggal' => $dateStr,
                        'hari' => $dayName,
                        'is_today' => ($dateStr === $today),
                        'jam_mulai' => substr($jadwal->jam_mulai, 0, 5),
                        'jam_selesai' => substr($jadwal->jam_selesai, 0, 5),
                        'kelas_id' => $jadwal->kelas_id,
                        'nama_kelas' => $jadwal->kelas ? $jadwal->kelas->nama_kelas : '',
                        'tingkat' => $jadwal->kelas ? $jadwal->kelas->tingkat : '',
                        'mapel_id' => $jadwal->mapel_id,
                        'nama_mapel' => $jadwal->mapel ? $jadwal->mapel->nama_mapel : '',
                        'kode_mapel' => $jadwal->mapel ? $jadwal->mapel->kode_mapel : '',
                        'guru_id' => $jadwal->guru_id,
                        'nama_guru' => $jadwal->guru ? $jadwal->guru->nama : '',
                        'status' => $status,
                        'jurnal_id' => $isFilled ? $jurnal->id : null,
                        'materi' => $isFilled ? $jurnal->materi : null,
                        'kegiatan' => $isFilled ? $jurnal->kegiatan : null,
                        'foto_kegiatan' => $isFilled ? $jurnal->foto_kegiatan : null,
                        'foto_kegiatan_url' => $isFilled ? $jurnal->foto_kegiatan_url : null,
                        'total_hadir' => $hadir,
                        'total_izin' => $izin,
                        'total_sakit' => $sakit,
                        'total_alpa' => $alpa,
                        'total_kehadiran' => $totalKehadiran,
                    ];
                }
            }

            // Mundur 1 hari
            $currentTimestamp = strtotime('-1 day', $currentTimestamp);
        }

        $totalSesi = count($sessions);
        $totalSudahDiisi = count(array_filter($sessions, fn($s) => $s['status'] === 'sudah_diisi'));
        $totalBelumDiisi = count(array_filter($sessions, fn($s) => $s['status'] === 'belum_diisi'));
        $totalHariIni = count(array_filter($sessions, fn($s) => $s['is_today']));

        // Filter status jika diminta (semua, belum_diisi, sudah_diisi, hari_ini)
        if ($request->filled('status')) {
            if ($request->status === 'belum_diisi' || $request->status === 'sudah_diisi') {
                $sessions = array_values(array_filter($sessions, fn($s) => $s['status'] === $request->status));
            } elseif ($request->status === 'hari_ini') {
                $sessions = array_values(array_filter($sessions, fn($s) => $s['is_today']));
            }
        }

        // Filter search jika ada
        if ($request->filled('search')) {
            $search = strtolower($request->search);
            $sessions = array_values(array_filter($sessions, function ($s) use ($search) {
                return str_contains(strtolower($s['nama_kelas']), $search)
                    || str_contains(strtolower($s['nama_mapel']), $search)
                    || str_contains(strtolower($s['nama_guru']), $search)
                    || str_contains(strtolower($s['materi'] ?? ''), $search);
            }));
        }

        return $this->sendResponse([
            'semester' => $semesterName,
            'start_date' => $startDate,
            'end_date' => $endDate,
            'total_sesi' => $totalSesi,
            'total_sudah_diisi' => $totalSudahDiisi,
            'total_belum_diisi' => $totalBelumDiisi,
            'total_hari_ini' => $totalHariIni,
            'sessions' => $sessions,
        ], 'Daftar sesi jadwal 1 semester hingga hari ini');
    }

    public function store(JurnalStoreRequest $request)
    {
        if ($request->filled('tanggal') && $request->tanggal > date('Y-m-d')) {
            return $this->sendError('Tidak dapat mengisi jurnal di waktu yang akan datang', [], 422);
        }

        $user = $request->user();
        $guruId = $user->id;

        if ($user->role === 'admin') {
            if ($request->filled('guru_id')) {
                $guruId = $request->guru_id;
            } elseif ($request->filled('jadwal_id')) {
                $jadwal = \App\Models\Jadwal::find($request->jadwal_id);
                if ($jadwal) {
                    $guruId = $jadwal->guru_id;
                }
            }
        } else {
            if ($request->filled('guru_id') && (int)$request->guru_id !== (int)$user->id) {
                return $this->sendError('Anda tidak memiliki izin membuat jurnal atas nama guru lain', [], 403);
            }
            if ($request->filled('jadwal_id')) {
                $jadwal = \App\Models\Jadwal::find($request->jadwal_id);
                if ($jadwal && (int)$jadwal->guru_id !== (int)$user->id) {
                    return $this->sendError('Anda tidak dapat membuat jurnal untuk jadwal milik guru lain', [], 403);
                }
            }
        }

        $fotoKegiatanPath = null;
        if ($request->hasFile('foto_kegiatan')) {
            $file = $request->file('foto_kegiatan');
            $filename = 'jurnal_' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $fotoKegiatanPath = $file->storeAs('jurnal_kegiatan', $filename, 'public');
        } elseif ($request->filled('foto_kegiatan') && is_string($request->foto_kegiatan)) {
            $fotoKegiatanPath = $request->foto_kegiatan;
        }

        DB::beginTransaction();
        try {
            $jurnal = Jurnal::create([
                'guru_id'       => $guruId,
                'jadwal_id'     => $request->jadwal_id,
                'tanggal'       => $request->tanggal,
                'materi'        => $request->materi,
                'kegiatan'      => $request->kegiatan,
                'metode'        => $request->metode,
                'media'         => $request->media,
                'kendala'       => $request->kendala,
                'tindak_lanjut' => $request->tindak_lanjut,
                'catatan'       => $request->catatan,
                'foto_kegiatan' => $fotoKegiatanPath,
            ]);

            // Save attendance if passed
            if ($request->has('kehadiran') && is_array($request->kehadiran)) {
                foreach ($request->kehadiran as $att) {
                    Kehadiran::create([
                        'jurnal_id'  => $jurnal->id,
                        'siswa_id'   => $att['siswa_id'],
                        'status'     => $att['status'] ?? 'Hadir',
                        'keterangan' => $att['keterangan'] ?? null,
                    ]);
                }
            }

            DB::commit();

            $jurnal->load(['guru', 'jadwal.kelas', 'jadwal.mapel']);

            return $this->sendResponse($jurnal, 'Jurnal mengajar berhasil disimpan', 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Gagal menyimpan jurnal: ' . $e->getMessage(), [], 500);
        }
    }

    public function show($id)
    {
        $jurnal = Jurnal::with(['guru', 'jadwal.kelas', 'jadwal.mapel', 'kehadiran.siswa'])->find($id);

        if (!$jurnal) {
            return $this->sendError('Jurnal tidak ditemukan', [], 404);
        }

        $hadir = $jurnal->kehadiran->where('status', 'Hadir')->count();
        $izin  = $jurnal->kehadiran->where('status', 'Izin')->count();
        $sakit = $jurnal->kehadiran->where('status', 'Sakit')->count();
        $alpa  = $jurnal->kehadiran->where('status', 'Alpa')->count();

        $arr = $jurnal->toArray();
        $arr['total_hadir'] = $hadir;
        $arr['total_izin']  = $izin;
        $arr['total_sakit'] = $sakit;
        $arr['total_alpa']  = $alpa;
        $arr['nama_guru']   = $jurnal->guru ? $jurnal->guru->nama : null;
        $arr['nama_kelas']  = $jurnal->jadwal && $jurnal->jadwal->kelas ? $jurnal->jadwal->kelas->nama_kelas : null;
        $arr['nama_mapel']  = $jurnal->jadwal && $jurnal->jadwal->mapel ? $jurnal->jadwal->mapel->nama_mapel : null;
        $arr['jam_mulai']   = $jurnal->jadwal ? substr($jurnal->jadwal->jam_mulai, 0, 5) : null;
        $arr['jam_selesai'] = $jurnal->jadwal ? substr($jurnal->jadwal->jam_selesai, 0, 5) : null;

        return $this->sendResponse($arr, 'Detail jurnal mengajar');
    }

    public function update(Request $request, $id)
    {
        $user = $request->user();
        $jurnal = Jurnal::find($id);

        if (!$jurnal) {
            return $this->sendError('Jurnal tidak ditemukan', [], 404);
        }

        if ($user->role !== 'admin' && $jurnal->guru_id !== $user->id) {
            return $this->sendError('Anda tidak memiliki izin mengubah jurnal ini', [], 403);
        }

        if ($request->filled('tanggal') && $request->tanggal > date('Y-m-d')) {
            return $this->sendError('Tidak dapat mengubah tanggal jurnal ke waktu yang akan datang', [], 422);
        }

        $data = $request->only([
            'tanggal',
            'materi',
            'kegiatan',
            'metode',
            'media',
            'kendala',
            'tindak_lanjut',
            'catatan',
        ]);

        if ($request->hasFile('foto_kegiatan')) {
            $request->validate([
                'foto_kegiatan' => 'file|image|mimes:jpeg,png,jpg,webp,gif|max:10240',
            ]);
            if ($jurnal->foto_kegiatan && Storage::disk('public')->exists($jurnal->foto_kegiatan)) {
                Storage::disk('public')->delete($jurnal->foto_kegiatan);
            }
            $file = $request->file('foto_kegiatan');
            $filename = 'jurnal_' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
            $data['foto_kegiatan'] = $file->storeAs('jurnal_kegiatan', $filename, 'public');
        } elseif ($request->has('hapus_foto') && filter_var($request->hapus_foto, FILTER_VALIDATE_BOOLEAN)) {
            if ($jurnal->foto_kegiatan && Storage::disk('public')->exists($jurnal->foto_kegiatan)) {
                Storage::disk('public')->delete($jurnal->foto_kegiatan);
            }
            $data['foto_kegiatan'] = null;
        } elseif ($request->filled('foto_kegiatan') && is_string($request->foto_kegiatan)) {
            $data['foto_kegiatan'] = $request->foto_kegiatan;
        }

        DB::beginTransaction();
        try {
            $jurnal->update($data);

            if ($request->has('kehadiran') && is_array($request->kehadiran)) {
                Kehadiran::where('jurnal_id', $jurnal->id)->delete();
                foreach ($request->kehadiran as $att) {
                    if (isset($att['siswa_id'])) {
                        Kehadiran::create([
                            'jurnal_id'  => $jurnal->id,
                            'siswa_id'   => $att['siswa_id'],
                            'status'     => $att['status'] ?? 'Hadir',
                            'keterangan' => $att['keterangan'] ?? null,
                        ]);
                    }
                }
            }

            DB::commit();

            $jurnal->load(['guru', 'jadwal.kelas', 'jadwal.mapel', 'kehadiran.siswa']);

            return $this->sendResponse($jurnal, 'Jurnal mengajar berhasil diperbarui');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Gagal memperbarui jurnal: ' . $e->getMessage(), [], 500);
        }
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $jurnal = Jurnal::find($id);

        if (!$jurnal) {
            return $this->sendError('Jurnal tidak ditemukan', [], 404);
        }

        if ($user->role !== 'admin' && $jurnal->guru_id !== $user->id) {
            return $this->sendError('Anda tidak memiliki izin menghapus jurnal ini', [], 403);
        }

        if ($jurnal->foto_kegiatan && Storage::disk('public')->exists($jurnal->foto_kegiatan)) {
            Storage::disk('public')->delete($jurnal->foto_kegiatan);
        }

        $jurnal->delete();

        return $this->sendResponse(null, 'Jurnal mengajar berhasil dihapus');
    }
}
