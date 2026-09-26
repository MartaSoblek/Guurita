<?php

namespace App\Http\Controllers\Api;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class GuruController extends BaseApiController
{
    /**
     * Display a listing of teachers (and optionally admins).
     */
    public function index(Request $request)
    {
        $query = User::withCount(['jadwal', 'jurnal']);

        // Optional role filter (default returns all teachers + admins, or filter by role)
        if ($request->filled('role')) {
            $role = strtolower(trim($request->role));
            if (in_array($role, ['guru', 'admin'])) {
                $query->where('role', $role);
            }
        }

        // Search query by name, NIP, email, or subject
        if ($request->filled('q')) {
            $q = trim($request->q);
            $query->where(function ($sub) use ($q) {
                $sub->where('nama', 'like', "%{$q}%")
                    ->orWhere('nip', 'like', "%{$q}%")
                    ->orWhere('email', 'like', "%{$q}%")
                    ->orWhere('mata_pelajaran', 'like', "%{$q}%");
            });
        }

        $guru = $query->orderBy('role', 'asc')
            ->orderBy('nama', 'asc')
            ->get();

        return $this->sendResponse($guru, 'Daftar data guru & tenaga pendidik');
    }

    /**
     * Display the specified teacher.
     */
    public function show($id)
    {
        $guru = User::withCount(['jadwal', 'jurnal'])
            ->with(['jadwal.kelas', 'jadwal.mataPelajaran'])
            ->find($id);

        if (!$guru) {
            return $this->sendError('Data guru tidak ditemukan', [], 404);
        }

        return $this->sendResponse($guru, 'Detail data guru');
    }

    /**
     * Store a newly created teacher in storage.
     */
    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data guru.', [], 403);
        }

        $validated = $request->validate([
            'nama'           => 'required|string|max:255',
            'nip'            => 'required|string|max:50|unique:users,nip',
            'email'          => 'required|email|max:255|unique:users,email',
            'password'       => 'required|string|min:6',
            'mata_pelajaran' => 'nullable|string|max:255',
            'role'           => 'required|in:guru,admin',
        ]);

        $guru = User::create([
            'nama'           => trim($validated['nama']),
            'nip'            => trim($validated['nip']),
            'email'          => strtolower(trim($validated['email'])),
            'password'       => Hash::make($validated['password']),
            'mata_pelajaran' => isset($validated['mata_pelajaran']) ? trim($validated['mata_pelajaran']) : null,
            'role'           => $validated['role'],
        ]);

        $guru->loadCount(['jadwal', 'jurnal']);

        return $this->sendResponse($guru, 'Data guru berhasil ditambahkan', 201);
    }

    /**
     * Update the specified teacher in storage.
     */
    public function update(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data guru.', [], 403);
        }

        $guru = User::find($id);

        if (!$guru) {
            return $this->sendError('Data guru tidak ditemukan', [], 404);
        }

        $validated = $request->validate([
            'nama'           => 'sometimes|required|string|max:255',
            'nip'            => 'sometimes|required|string|max:50|unique:users,nip,' . $id,
            'email'          => 'sometimes|required|email|max:255|unique:users,email,' . $id,
            'password'       => 'nullable|string|min:6',
            'mata_pelajaran' => 'nullable|string|max:255',
            'role'           => 'sometimes|required|in:guru,admin',
        ]);

        if (isset($validated['nama'])) {
            $guru->nama = trim($validated['nama']);
        }
        if (isset($validated['nip'])) {
            $guru->nip = trim($validated['nip']);
        }
        if (isset($validated['email'])) {
            $guru->email = strtolower(trim($validated['email']));
        }
        if (!empty($validated['password'])) {
            $guru->password = Hash::make($validated['password']);
        }
        if (array_key_exists('mata_pelajaran', $validated)) {
            $guru->mata_pelajaran = !empty($validated['mata_pelajaran']) ? trim($validated['mata_pelajaran']) : null;
        }
        if (isset($validated['role'])) {
            $guru->role = $validated['role'];
        }

        $guru->save();
        $guru->loadCount(['jadwal', 'jurnal']);

        return $this->sendResponse($guru, 'Data guru berhasil diperbarui');
    }

    /**
     * Remove the specified teacher from storage.
     */
    public function destroy(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat mengelola data guru.', [], 403);
        }

        // Prevent admin from deleting themselves
        if ((int)$request->user()->id === (int)$id) {
            return $this->sendError('Anda tidak dapat menghapus akun Anda sendiri.', [], 422);
        }

        $guru = User::find($id);

        if (!$guru) {
            return $this->sendError('Data guru tidak ditemukan', [], 404);
        }

        // Safety check: Cannot delete teacher if they have active recorded journals
        if ($guru->jurnal()->count() > 0) {
            return $this->sendError('Guru tidak dapat dihapus karena sudah memiliki riwayat jurnal KBM yang tercatat di sistem.', [], 422);
        }

        // Check if teacher is assigned to schedules
        if ($guru->jadwal()->count() > 0) {
            return $this->sendError('Guru tidak dapat dihapus karena masih terdaftar pada jadwal mengajar aktif. Harap alihkan atau hapus jadwal terlebih dahulu.', [], 422);
        }

        $guru->delete();

        return $this->sendResponse(null, 'Data guru berhasil dihapus dari sistem');
    }

    /**
     * Generate an impersonation session/token for the specified teacher (Admin only).
     */
    public function impersonate(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return $this->sendError('Akses ditolak. Hanya Administrator yang dapat login sebagai pengguna lain.', [], 403);
        }

        $guru = User::find($id);

        if (!$guru) {
            return $this->sendError('Data guru tidak ditemukan', [], 404);
        }

        $token = $guru->createToken('gurita_impersonate_token')->plainTextToken;

        return $this->sendResponse([
            'token' => $token,
            'user' => [
                'id' => $guru->id,
                'nama' => $guru->nama,
                'nip' => $guru->nip,
                'email' => $guru->email,
                'role' => $guru->role ?? 'guru',
                'foto' => $guru->foto,
                'mata_pelajaran' => $guru->mata_pelajaran,
            ],
        ], "Berhasil menghasilkan sesi login otomatis untuk {$guru->nama}");
    }
}

