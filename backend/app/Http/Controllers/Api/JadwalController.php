<?php

namespace App\Http\Controllers\Api;

use App\Models\Jadwal;
use Carbon\Carbon;
use Illuminate\Http\Request;

class JadwalController extends BaseApiController
{
    private $hariIndo = [
        1 => 'Senin',
        2 => 'Selasa',
        3 => 'Rabu',
        4 => 'Kamis',
        5 => 'Jumat',
        6 => 'Sabtu',
        7 => 'Minggu',
    ];

    public function index(Request $request)
    {
        $user = $request->user();
        $isAdmin = ($user->role === 'admin');

        $query = Jadwal::with(['kelas', 'mapel', 'guru'])
            ->orderByRaw("FIELD(hari, 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu')")
            ->orderBy('jam_mulai', 'asc');

        if ($isAdmin) {
            if ($request->filled('guru_id')) {
                $query->where('guru_id', $request->guru_id);
            }
        } else {
            $query->where('guru_id', $user->id);
        }

        $jadwal = $query->get();

        return $this->sendResponse($jadwal, 'Daftar jadwal mengajar');
    }

    public function hariIni(Request $request)
    {
        $user = $request->user();
        $isAdmin = ($user->role === 'admin');
        $now = Carbon::now();
        $hariIni = $this->hariIndo[$now->dayOfWeekIso] ?? 'Senin';

        $query = Jadwal::with(['kelas', 'mapel', 'guru'])
            ->where('hari', $hariIni)
            ->orderBy('jam_mulai', 'asc');

        if ($isAdmin) {
            if ($request->filled('guru_id')) {
                $query->where('guru_id', $request->guru_id);
            }
        } else {
            $query->where('guru_id', $user->id);
        }

        $jadwal = $query->get();

        return $this->sendResponse($jadwal, 'Jadwal hari ' . $hariIni);
    }

    public function show($id)
    {
        $jadwal = Jadwal::with(['kelas', 'mapel', 'guru'])->find($id);

        if (!$jadwal) {
            return $this->sendError('Jadwal tidak ditemukan', [], 404);
        }

        return $this->sendResponse($jadwal, 'Detail jadwal mengajar');
    }

    public function store(Request $request)
    {
        $user = $request->user();
        $isAdmin = ($user->role === 'admin');

        $rules = [
            'kelas_id'    => 'required|exists:kelas,id',
            'mapel_id'    => 'required|exists:mata_pelajaran,id',
            'hari'        => 'required|in:Senin,Selasa,Rabu,Kamis,Jumat,Sabtu',
            'jam_mulai'   => 'required|string',
            'jam_selesai' => 'required|string',
        ];

        if ($isAdmin) {
            $rules['guru_id'] = 'required|exists:users,id';
        }

        $validated = $request->validate($rules);

        if (!$isAdmin) {
            if ($request->filled('guru_id') && (int)$request->guru_id !== (int)$user->id) {
                return $this->sendError('Anda tidak memiliki izin membuat jadwal atas nama guru lain', [], 403);
            }
        }

        $guruId = $isAdmin ? $request->guru_id : $user->id;

        // Ensure time format HH:MM
        $jamMulai = substr($validated['jam_mulai'], 0, 5);
        $jamSelesai = substr($validated['jam_selesai'], 0, 5);

        $jadwal = Jadwal::create([
            'guru_id'     => $guruId,
            'kelas_id'    => $validated['kelas_id'],
            'mapel_id'    => $validated['mapel_id'],
            'hari'        => $validated['hari'],
            'jam_mulai'   => $jamMulai,
            'jam_selesai' => $jamSelesai,
        ]);

        $jadwal->load(['kelas', 'mapel', 'guru']);

        return $this->sendResponse($jadwal, 'Jadwal mengajar berhasil ditambahkan', 201);
    }

    public function update(Request $request, $id)
    {
        $user = $request->user();
        $jadwal = Jadwal::find($id);

        if (!$jadwal) {
            return $this->sendError('Jadwal tidak ditemukan', [], 404);
        }

        if ($user->role !== 'admin') {
            if ($jadwal->guru_id !== $user->id) {
                return $this->sendError('Anda tidak memiliki izin mengubah jadwal guru lain', [], 403);
            }
            if ($request->filled('guru_id') && (int)$request->guru_id !== (int)$user->id) {
                return $this->sendError('Anda tidak memiliki izin mengalihkan jadwal ke guru lain', [], 403);
            }
        }

        $rules = [
            'kelas_id'    => 'sometimes|required|exists:kelas,id',
            'mapel_id'    => 'sometimes|required|exists:mata_pelajaran,id',
            'hari'        => 'sometimes|required|in:Senin,Selasa,Rabu,Kamis,Jumat,Sabtu',
            'jam_mulai'   => 'sometimes|required|string',
            'jam_selesai' => 'sometimes|required|string',
        ];

        if ($user->role === 'admin') {
            $rules['guru_id'] = 'sometimes|required|exists:users,id';
        }

        $request->validate($rules);

        $data = $request->only(['kelas_id', 'mapel_id', 'hari']);
        if ($request->filled('jam_mulai')) {
            $data['jam_mulai'] = substr($request->jam_mulai, 0, 5);
        }
        if ($request->filled('jam_selesai')) {
            $data['jam_selesai'] = substr($request->jam_selesai, 0, 5);
        }
        if ($user->role === 'admin' && $request->filled('guru_id')) {
            $data['guru_id'] = $request->guru_id;
        }

        $jadwal->update($data);
        $jadwal->load(['kelas', 'mapel', 'guru']);

        return $this->sendResponse($jadwal, 'Jadwal mengajar berhasil diperbarui');
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $jadwal = Jadwal::find($id);

        if (!$jadwal) {
            return $this->sendError('Jadwal tidak ditemukan', [], 404);
        }

        if ($user->role !== 'admin' && $jadwal->guru_id !== $user->id) {
            return $this->sendError('Anda tidak memiliki izin menghapus jadwal guru lain', [], 403);
        }

        $jadwal->delete();

        return $this->sendResponse(null, 'Jadwal mengajar berhasil dihapus');
    }
}
