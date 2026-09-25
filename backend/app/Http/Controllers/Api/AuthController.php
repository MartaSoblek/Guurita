<?php

namespace App\Http\Controllers\Api;

use App\Http\Requests\LoginRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends BaseApiController
{
    public function login(LoginRequest $request)
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->sendError('Email atau password tidak valid', [
                'auth' => ['Kombinasi email dan kata sandi salah.']
            ], 401);
        }

        // Revoke existing tokens for a clean session if needed
        $user->tokens()->delete();

        $token = $user->createToken('gurita_token')->plainTextToken;

        return $this->sendResponse([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'nama' => $user->nama,
                'nip' => $user->nip,
                'email' => $user->email,
                'role' => $user->role ?? 'guru',
                'foto' => $user->foto,
                'mata_pelajaran' => $user->mata_pelajaran,
            ],
        ], 'Login berhasil ke sistem GURITA');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return $this->sendResponse(null, 'Berhasil keluar dari akun GURITA');
    }

    public function profile(Request $request)
    {
        $user = $request->user();

        return $this->sendResponse([
            'id' => $user->id,
            'nama' => $user->nama,
            'nip' => $user->nip,
            'email' => $user->email,
            'role' => $user->role ?? 'guru',
            'foto' => $user->foto,
            'mata_pelajaran' => $user->mata_pelajaran,
        ], 'Data profil pengguna');
    }
}
