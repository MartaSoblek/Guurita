<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $table = 'users';

    protected $fillable = [
        'nama',
        'nip',
        'email',
        'password',
        'role',
        'foto',
        'mata_pelajaran',
    ];

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function isGuru(): bool
    {
        return $this->role === 'guru';
    }

    protected $hidden = [
        'password',
        'remember_token',
    ];

    public function jadwal()
    {
        return $this->hasMany(Jadwal::class, 'guru_id');
    }

    public function jurnal()
    {
        return $this->hasMany(Jurnal::class, 'guru_id');
    }
}
