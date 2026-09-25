<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\ProfileUpdateRequest;
use Illuminate\Support\Facades\Hash;

class ProfileController extends BaseApiController
{
    public function update(ProfileUpdateRequest $request)
    {
        $user = $request->user();

        // If user wants to change password
        if ($request->filled('new_password')) {
            if (!$request->filled('current_password') || !Hash::check($request->current_password, $user->password)) {
                return $this->sendError('Password saat ini salah', [
                    'current_password' => ['Password saat ini tidak cocok.']
                ], 422);
            }

            $user->password = Hash::make($request->new_password);
        }

        $user->nama = $request->nama;
        $user->email = $request->email;
        $user->save();

        return $this->sendResponse([
            'id'             => $user->id,
            'nama'           => $user->nama,
            'nip'            => $user->nip,
            'email'          => $user->email,
            'role'           => $user->role ?? 'guru',
            'foto'           => $user->foto,
            'mata_pelajaran' => $user->mata_pelajaran,
        ], 'Profil pengguna berhasil diperbarui');
    }

    public function guruList()
    {
        $guru = \App\Models\User::where('role', 'guru')
            ->select('id', 'nama', 'nip', 'email', 'mata_pelajaran', 'foto')
            ->orderBy('nama', 'asc')
            ->get();

        return $this->sendResponse($guru, 'Daftar guru pengajar');
    }
}
