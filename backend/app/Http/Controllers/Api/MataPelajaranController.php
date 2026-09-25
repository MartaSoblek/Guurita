<?php

namespace App\Http\Controllers\Api;

use App\Models\MataPelajaran;
use Illuminate\Http\Request;

class MataPelajaranController extends BaseApiController
{
    public function index()
    {
        $mapel = MataPelajaran::withCount('jadwal')->orderBy('nama_mapel', 'asc')->get();

        return $this->sendResponse($mapel, 'Daftar mata pelajaran');
    }

    public function show($id)
    {
        $mapel = MataPelajaran::withCount('jadwal')->find($id);

        if (!$mapel) {
            return $this->sendError('Mata pelajaran tidak ditemukan', [], 404);
        }

        return $this->sendResponse($mapel, 'Detail mata pelajaran');
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola mata pelajaran.', [], 403);
        }

        $validated = $request->validate([
            'kode_mapel' => 'required|string|max:20|unique:mata_pelajaran,kode_mapel',
            'nama_mapel' => 'required|string|max:255',
        ]);

        $mapel = MataPelajaran::create([
            'kode_mapel' => strtoupper(trim($validated['kode_mapel'])),
            'nama_mapel' => trim($validated['nama_mapel']),
        ]);

        return $this->sendResponse($mapel, 'Mata pelajaran berhasil ditambahkan', 201);
    }

    public function update(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola mata pelajaran.', [], 403);
        }

        $mapel = MataPelajaran::find($id);

        if (!$mapel) {
            return $this->sendError('Mata pelajaran tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'kode_mapel' => 'sometimes|required|string|max:20|unique:mata_pelajaran,kode_mapel,' . $id,
            'nama_mapel' => 'sometimes|required|string|max:255',
        ]);

        $data = [];
        if (isset($validated['kode_mapel'])) {
            $data['kode_mapel'] = strtoupper(trim($validated['kode_mapel']));
        }
        if (isset($validated['nama_mapel'])) {
            $data['nama_mapel'] = trim($validated['nama_mapel']);
        }

        $mapel->update($data);

        return $this->sendResponse($mapel, 'Mata pelajaran berhasil diperbarui');
    }

    public function destroy(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola mata pelajaran.', [], 403);
        }

        $mapel = MataPelajaran::find($id);

        if (!$mapel) {
            return $this->sendError('Mata pelajaran tidak ditemukan', [], 404);
        }

        // Check if subject is actively referenced in schedules
        if ($mapel->jadwal()->count() > 0) {
            return $this->sendError('Mata pelajaran tidak dapat dihapus karena masih digunakan pada jadwal mengajar.', [], 422);
        }

        $mapel->delete();

        return $this->sendResponse(null, 'Mata pelajaran berhasil dihapus');
    }
}
