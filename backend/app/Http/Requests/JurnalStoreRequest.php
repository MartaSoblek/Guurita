<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class JurnalStoreRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'jadwal_id' => 'nullable|exists:jadwal,id',
            'tanggal' => 'required|date|before_or_equal:today',
            'materi' => 'required|string|max:255',
            'kegiatan' => 'nullable|string',
            'metode' => 'nullable|string|max:255',
            'media' => 'nullable|string|max:255',
            'kendala' => 'nullable|string',
            'tindak_lanjut' => 'nullable|string',
            'catatan' => 'nullable|string',
            'foto_kegiatan' => $this->hasFile('foto_kegiatan') ? 'file|image|mimes:jpeg,png,jpg,webp,gif|max:10240' : 'nullable',
            'kehadiran' => 'nullable|array',
            'kehadiran.*.siswa_id' => 'required_with:kehadiran|exists:siswa,id',
            'kehadiran.*.status' => 'required_with:kehadiran|in:Hadir,Izin,Sakit,Alpa',
            'kehadiran.*.keterangan' => 'nullable|string|max:255',
        ];
    }

    public function messages()
    {
        return [
            'tanggal.required' => 'Tanggal KBM wajib diisi',
            'tanggal.before_or_equal' => 'Tidak dapat mengisi jurnal di waktu yang akan datang',
            'materi.required' => 'Materi pembelajaran wajib diisi',
            'foto_kegiatan.image' => 'Berkas foto kegiatan harus berupa format gambar (JPG, PNG, WEBP)',
            'foto_kegiatan.max' => 'Ukuran file foto kegiatan maksimal 10MB',
        ];
    }

    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => 'Validasi data jurnal gagal',
            'errors' => $validator->errors(),
        ], 422));
    }
}
