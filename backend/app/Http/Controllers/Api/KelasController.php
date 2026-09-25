<?php

namespace App\Http\Controllers\Api;

use App\Models\Kelas;
use Illuminate\Http\Request;

class KelasController extends BaseApiController
{
    public function index()
    {
        $kelas = Kelas::withCount(['siswa', 'jadwal'])
            ->orderBy('tingkat', 'asc')
            ->orderBy('nama_kelas', 'asc')
            ->get();

        return $this->sendResponse($kelas, 'Daftar kelas');
    }

    public function show($id)
    {
        $kelas = Kelas::withCount(['siswa', 'jadwal'])->find($id);

        if (!$kelas) {
            return $this->sendError('Kelas tidak ditemukan', [], 404);
        }

        return $this->sendResponse($kelas, 'Detail kelas');
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data kelas.', [], 403);
        }

        $validated = $request->validate([
            'nama_kelas' => 'required|string|max:50|unique:kelas,nama_kelas',
            'tingkat' => 'required|string|max:10',
        ]);

        $kelas = Kelas::create([
            'nama_kelas' => trim($validated['nama_kelas']),
            'tingkat' => strtoupper(trim($validated['tingkat'])),
        ]);

        $kelas->loadCount(['siswa', 'jadwal']);

        return $this->sendResponse($kelas, 'Data kelas berhasil ditambahkan', 201);
    }

    public function update(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data kelas.', [], 403);
        }

        $kelas = Kelas::find($id);

        if (!$kelas) {
            return $this->sendError('Kelas tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'nama_kelas' => 'sometimes|required|string|max:50|unique:kelas,nama_kelas,' . $id,
            'tingkat' => 'sometimes|required|string|max:10',
        ]);

        $data = [];
        if (isset($validated['nama_kelas'])) {
            $data['nama_kelas'] = trim($validated['nama_kelas']);
        }
        if (isset($validated['tingkat'])) {
            $data['tingkat'] = strtoupper(trim($validated['tingkat']));
        }

        $kelas->update($data);
        $kelas->loadCount(['siswa', 'jadwal']);

        return $this->sendResponse($kelas, 'Data kelas berhasil diperbarui');
    }

    public function destroy(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data kelas.', [], 403);
        }

        $kelas = Kelas::find($id);

        if (!$kelas) {
            return $this->sendError('Kelas tidak ditemukan', [], 404);
        }

        // Integrity check: prevent delete if class still has students registered
        if ($kelas->siswa()->count() > 0) {
            return $this->sendError('Kelas tidak dapat dihapus karena masih memiliki data siswa terdaftar.', [], 422);
        }

        // Integrity check: prevent delete if class is used in schedules
        if ($kelas->jadwal()->count() > 0) {
            return $this->sendError('Kelas tidak dapat dihapus karena masih digunakan pada jadwal mengajar.', [], 422);
        }

        $kelas->delete();

        return $this->sendResponse(null, 'Data kelas berhasil dihapus');
    }

    public function siswa($id)
    {
        $kelas = Kelas::find($id);

        if (!$kelas) {
            return $this->sendError('Kelas tidak ditemukan', [], 404);
        }

        $siswa = $kelas->siswa()->orderBy('nama', 'asc')->get();

        return $this->sendResponse($siswa, 'Daftar siswa kelas ' . $kelas->nama_kelas);
    }
}
