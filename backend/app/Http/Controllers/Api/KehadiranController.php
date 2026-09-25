<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\KehadiranBatchRequest;
use App\Models\Kehadiran;
use App\Models\Jurnal;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class KehadiranController extends BaseApiController
{
    public function byJurnal($jurnalId)
    {
        $jurnal = Jurnal::find($jurnalId);

        if (!$jurnal) {
            return $this->sendError('Jurnal tidak ditemukan', [], 404);
        }

        $kehadiran = Kehadiran::with('siswa')
            ->where('jurnal_id', $jurnalId)
            ->join('siswa', 'kehadiran.siswa_id', '=', 'siswa.id')
            ->orderBy('siswa.nama', 'asc')
            ->select('kehadiran.*')
            ->get();

        return $this->sendResponse($kehadiran, 'Daftar presensi siswa');
    }

    public function storeOrUpdateBatch(KehadiranBatchRequest $request, $jurnalId)
    {
        $jurnal = Jurnal::find($jurnalId);

        if (!$jurnal) {
            return $this->sendError('Jurnal tidak ditemukan', [], 404);
        }

        $user = $request->user();
        if ($user->role !== 'admin' && (int)$jurnal->guru_id !== (int)$user->id) {
            return $this->sendError('Anda tidak memiliki izin mengelola presensi jurnal guru lain', [], 403);
        }

        DB::beginTransaction();
        try {
            foreach ($request->kehadiran as $item) {
                Kehadiran::updateOrCreate(
                    [
                        'jurnal_id' => $jurnalId,
                        'siswa_id'  => $item['siswa_id'],
                    ],
                    [
                        'status'     => $item['status'],
                        'keterangan' => $item['keterangan'] ?? null,
                    ]
                );
            }

            DB::commit();

            return $this->sendResponse(null, 'Kehadiran siswa berhasil disimpan');
        } catch (\Exception $e) {
            DB::rollBack();
            return $this->sendError('Gagal menyimpan kehadiran: ' . $e->getMessage(), [], 500);
        }
    }

    public function update(Request $request, $id)
    {
        $kehadiran = Kehadiran::find($id);

        if (!$kehadiran) {
            return $this->sendError('Data kehadiran tidak ditemukan', [], 404);
        }

        $user = $request->user();
        $kehadiran->load('jurnal');
        if ($user->role !== 'admin' && $kehadiran->jurnal && (int)$kehadiran->jurnal->guru_id !== (int)$user->id) {
            return $this->sendError('Anda tidak memiliki izin mengubah status presensi jurnal guru lain', [], 403);
        }

        $request->validate([
            'status' => 'required|in:Hadir,Izin,Sakit,Alpa',
            'keterangan' => 'nullable|string|max:255',
        ]);

        $kehadiran->update($request->only(['status', 'keterangan']));

        return $this->sendResponse($kehadiran, 'Status kehadiran diperbarui');
    }
}
