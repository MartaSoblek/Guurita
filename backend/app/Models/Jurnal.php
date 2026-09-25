<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Jurnal extends Model
{
    use HasFactory;

    protected $table = 'jurnal';

    protected $fillable = [
        'guru_id',
        'jadwal_id',
        'tanggal',
        'materi',
        'kegiatan',
        'metode',
        'media',
        'kendala',
        'tindak_lanjut',
        'catatan',
        'foto_kegiatan',
    ];

    protected $appends = [
        'foto_kegiatan_url',
    ];

    public function getFotoKegiatanUrlAttribute()
    {
        if (!$this->foto_kegiatan) {
            return null;
        }

        if (filter_var($this->foto_kegiatan, FILTER_VALIDATE_URL)) {
            return $this->foto_kegiatan;
        }

        return url('storage/' . ltrim($this->foto_kegiatan, '/'));
    }

    public function guru()
    {
        return $this->belongsTo(User::class, 'guru_id');
    }

    public function jadwal()
    {
        return $this->belongsTo(Jadwal::class, 'jadwal_id');
    }

    public function kehadiran()
    {
        return $this->hasMany(Kehadiran::class, 'jurnal_id');
    }
}
