<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class KehadiranBatchRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'kehadiran' => 'required|array',
            'kehadiran.*.siswa_id' => 'required|exists:siswa,id',
            'kehadiran.*.status' => 'required|in:Hadir,Izin,Sakit,Alpa',
            'kehadiran.*.keterangan' => 'nullable|string|max:255',
        ];
    }

    protected function failedValidation(Validator $validator)
    {
        throw new HttpResponseException(response()->json([
            'success' => false,
            'message' => 'Validasi data kehadiran gagal',
            'errors' => $validator->errors(),
        ], 422));
    }
}
