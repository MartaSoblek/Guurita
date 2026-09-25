<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class GuritaApiTest extends TestCase
{
    public function test_login_successful()
    {
        $response = $this->postJson('/api/login', [
            'email' => 'surya@smkn1abang.sch.id',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'data' => ['token', 'user'],
            ]);
    }

    public function test_login_invalid_password()
    {
        $response = $this->postJson('/api/login', [
            'email' => 'surya@smkn1abang.sch.id',
            'password' => 'wrong_password',
        ]);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_authenticated_profile()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/profile');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'email' => 'surya@smkn1abang.sch.id',
                ],
            ]);
    }

    public function test_dashboard_endpoint()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/dashboard');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ])
            ->assertJsonStructure([
                'data' => [
                    'hari_ini',
                    'total_kelas_hari_ini',
                    'total_siswa_hadir',
                    'total_jurnal_hari_ini',
                ],
            ]);
    }

    public function test_jadwal_endpoint()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/jadwal');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_kelas_endpoint()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/kelas');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_mapel_endpoint()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/mapel');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_jurnal_history_endpoint()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/jurnal');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_laporan_kehadiran_endpoint()
    {
        $user = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/laporan/kehadiran');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_admin_login_and_role()
    {
        $response = $this->postJson('/api/login', [
            'email' => 'admin@smkn1abang.sch.id',
            'password' => 'password',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'user' => [
                        'email' => 'admin@smkn1abang.sch.id',
                        'role' => 'admin',
                    ],
                ],
            ]);
    }

    public function test_admin_can_access_all_teacher_schedules()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/jadwal');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        // Should return schedules from all teachers (7 total seeded schedules)
        $data = $response->json('data');
        $this->assertGreaterThan(1, count($data));
    }

    public function test_admin_can_access_all_teacher_journals()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/jurnal');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $data = $response->json('data');
        $this->assertNotEmpty($data);
    }

    public function test_admin_can_fetch_guru_list()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/guru');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $data = $response->json('data');
        $this->assertCount(2, $data);
    }

    public function test_can_create_jadwal_as_guru()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();
        $mapel = \App\Models\MataPelajaran::first();

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/jadwal', [
            'kelas_id' => $kelas->id,
            'mapel_id' => $mapel->id,
            'hari' => 'Sabtu',
            'jam_mulai' => '08:00',
            'jam_selesai' => '09:30',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'hari' => 'Sabtu',
                    'guru_id' => $guru->id,
                ],
            ]);
    }

    public function test_can_update_jadwal()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->first();

        $response = $this->actingAs($guru, 'sanctum')->putJson("/api/jadwal/{$jadwal->id}", [
            'jam_mulai' => '08:15',
            'jam_selesai' => '09:45',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'jam_mulai' => '08:15',
                    'jam_selesai' => '09:45',
                ],
            ]);
    }

    public function test_can_delete_jadwal()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->where('hari', 'Sabtu')->first();
        if (!$jadwal) {
            $jadwal = \App\Models\Jadwal::create([
                'guru_id' => $guru->id,
                'kelas_id' => \App\Models\Kelas::first()->id,
                'mapel_id' => \App\Models\MataPelajaran::first()->id,
                'hari' => 'Sabtu',
                'jam_mulai' => '10:00',
                'jam_selesai' => '11:30',
            ]);
        }

        $response = $this->actingAs($guru, 'sanctum')->deleteJson("/api/jadwal/{$jadwal->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('jadwal', ['id' => $jadwal->id]);
    }

    public function test_admin_can_create_jadwal_for_teacher()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $guru = User::where('email', 'dewi@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();
        $mapel = \App\Models\MataPelajaran::first();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/jadwal', [
            'guru_id' => $guru->id,
            'kelas_id' => $kelas->id,
            'mapel_id' => $mapel->id,
            'hari' => 'Jumat',
            'jam_mulai' => '13:00',
            'jam_selesai' => '14:30',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'guru_id' => $guru->id,
                    'hari' => 'Jumat',
                ],
            ]);
    }

    public function test_teacher_cannot_create_jadwal_for_another_teacher()
    {
        $guru1 = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $guru2 = User::where('email', 'dewi@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();
        $mapel = \App\Models\MataPelajaran::first();

        $response = $this->actingAs($guru1, 'sanctum')->postJson('/api/jadwal', [
            'guru_id' => $guru2->id,
            'kelas_id' => $kelas->id,
            'mapel_id' => $mapel->id,
            'hari' => 'Kamis',
            'jam_mulai' => '10:00',
            'jam_selesai' => '11:30',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_teacher_cannot_update_another_teachers_jadwal()
    {
        $guru1 = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $guru2 = User::where('email', 'dewi@smkn1abang.sch.id')->first();
        $jadwalGuru2 = \App\Models\Jadwal::where('guru_id', $guru2->id)->first();

        $response = $this->actingAs($guru1, 'sanctum')->putJson("/api/jadwal/{$jadwalGuru2->id}", [
            'jam_mulai' => '07:00',
            'jam_selesai' => '08:30',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_teacher_cannot_delete_another_teachers_jadwal()
    {
        $guru1 = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $guru2 = User::where('email', 'dewi@smkn1abang.sch.id')->first();
        $jadwalGuru2 = \App\Models\Jadwal::where('guru_id', $guru2->id)->first();

        $response = $this->actingAs($guru1, 'sanctum')->deleteJson("/api/jadwal/{$jadwalGuru2->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_admin_can_create_mapel()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/mapel', [
            'kode_mapel' => 'PBO-04',
            'nama_mapel' => 'Pemrograman Berorientasi Objek',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'kode_mapel' => 'PBO-04',
                    'nama_mapel' => 'Pemrograman Berorientasi Objek',
                ],
            ]);
    }

    public function test_admin_can_update_mapel()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $mapel = \App\Models\MataPelajaran::where('kode_mapel', 'PBO-04')->first();
        if (!$mapel) {
            $mapel = \App\Models\MataPelajaran::create([
                'kode_mapel' => 'PBO-04',
                'nama_mapel' => 'Pemrograman Berorientasi Objek',
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/mapel/{$mapel->id}", [
            'nama_mapel' => 'Pemrograman Berorientasi Objek Lanjutan',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'nama_mapel' => 'Pemrograman Berorientasi Objek Lanjutan',
                ],
            ]);
    }

    public function test_admin_can_delete_mapel()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $mapel = \App\Models\MataPelajaran::where('kode_mapel', 'PBO-04')->first();
        if (!$mapel) {
            $mapel = \App\Models\MataPelajaran::create([
                'kode_mapel' => 'PBO-04',
                'nama_mapel' => 'Pemrograman Berorientasi Objek Lanjutan',
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->deleteJson("/api/mapel/{$mapel->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('mata_pelajaran', ['id' => $mapel->id]);
    }

    public function test_teacher_cannot_create_mapel()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/mapel', [
            'kode_mapel' => 'HACK-99',
            'nama_mapel' => 'Unauthorized Subject',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_teacher_cannot_delete_mapel()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $mapel = \App\Models\MataPelajaran::first();

        $response = $this->actingAs($guru, 'sanctum')->deleteJson("/api/mapel/{$mapel->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_admin_can_create_kelas()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/kelas', [
            'nama_kelas' => 'XII RPL 1',
            'tingkat' => 'XII',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'nama_kelas' => 'XII RPL 1',
                    'tingkat' => 'XII',
                ],
            ]);
    }

    public function test_admin_can_update_kelas()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::where('nama_kelas', 'XII RPL 1')->first();
        if (!$kelas) {
            $kelas = \App\Models\Kelas::create([
                'nama_kelas' => 'XII RPL 1',
                'tingkat' => 'XII',
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/kelas/{$kelas->id}", [
            'nama_kelas' => 'XII RPL Unggulan',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'nama_kelas' => 'XII RPL Unggulan',
                ],
            ]);
    }

    public function test_admin_can_delete_empty_kelas()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::where('nama_kelas', 'XII RPL Unggulan')->first();
        if (!$kelas) {
            $kelas = \App\Models\Kelas::create([
                'nama_kelas' => 'XII RPL Unggulan',
                'tingkat' => 'XII',
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->deleteJson("/api/kelas/{$kelas->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('kelas', ['id' => $kelas->id]);
    }

    public function test_admin_cannot_delete_kelas_with_students()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        // Kelas with students from seeder, e.g. X TKJ
        $kelas = \App\Models\Kelas::where('nama_kelas', 'X TKJ')->first();

        $response = $this->actingAs($admin, 'sanctum')->deleteJson("/api/kelas/{$kelas->id}");

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_teacher_cannot_create_kelas()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/kelas', [
            'nama_kelas' => 'Kelas Ilegal',
            'tingkat' => 'X',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_teacher_cannot_delete_kelas()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();

        $response = $this->actingAs($guru, 'sanctum')->deleteJson("/api/kelas/{$kelas->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_can_fetch_siswa_list_with_kelas_filter()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();

        $response = $this->actingAs($guru, 'sanctum')->getJson("/api/siswa?kelas_id={$kelas->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);
        $this->assertNotEmpty($response->json('data'));
    }

    public function test_admin_can_create_siswa()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/siswa', [
            'nis' => '999901',
            'nisn' => '0089999901',
            'nama' => 'Siswa Baru Berprestasi',
            'kelas_id' => $kelas->id,
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'nis' => '999901',
                    'nama' => 'Siswa Baru Berprestasi',
                ],
            ]);
    }

    public function test_admin_can_update_siswa()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $siswa = \App\Models\Siswa::where('nis', '999901')->first();
        if (!$siswa) {
            $kelas = \App\Models\Kelas::first();
            $siswa = \App\Models\Siswa::create([
                'nis' => '999901',
                'nisn' => '0089999901',
                'nama' => 'Siswa Baru Berprestasi',
                'kelas_id' => $kelas->id,
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/siswa/{$siswa->id}", [
            'nama' => 'Siswa Baru Berprestasi Juara 1',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'nama' => 'Siswa Baru Berprestasi Juara 1',
                ],
            ]);
    }

    public function test_admin_can_delete_siswa()
    {
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $siswa = \App\Models\Siswa::where('nis', '999901')->first();
        if (!$siswa) {
            $kelas = \App\Models\Kelas::first();
            $siswa = \App\Models\Siswa::create([
                'nis' => '999901',
                'nisn' => '0089999901',
                'nama' => 'Siswa Hapus Test',
                'kelas_id' => $kelas->id,
            ]);
        }

        $response = $this->actingAs($admin, 'sanctum')->deleteJson("/api/siswa/{$siswa->id}");

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $this->assertDatabaseMissing('siswa', ['id' => $siswa->id]);
    }

    public function test_teacher_cannot_create_siswa()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/siswa', [
            'nis' => '999902',
            'nisn' => '0089999902',
            'nama' => 'Siswa Unauthorized',
            'kelas_id' => $kelas->id,
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_teacher_cannot_delete_siswa()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $siswa = \App\Models\Siswa::first();

        $response = $this->actingAs($guru, 'sanctum')->deleteJson("/api/siswa/{$siswa->id}");

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_can_download_siswa_template()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($guru, 'sanctum')->get('/api/siswa/template');

        $response->assertStatus(200);
        $this->assertStringContainsString('nis,nisn,nama', $response->getContent());
    }

    public function test_can_download_siswa_excel_template()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($guru, 'sanctum')->get('/api/siswa/template/excel');

        $response->assertStatus(200);
        $this->assertTrue(str_contains($response->headers->get('content-type'), 'spreadsheetml') || str_contains($response->headers->get('content-disposition'), 'template_import_siswa.xlsx'));
    }

    public function test_admin_can_import_siswa_via_json_array()
    {
        \App\Models\Siswa::whereIn('nis', ['888801', '888802'])->delete();
        $admin = User::where('email', 'admin@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/siswa/import', [
            'kelas_id' => $kelas->id,
            'students' => [
                [
                    'nis' => '888801',
                    'nisn' => '0088888801',
                    'nama' => 'Siswa Import Excel 1',
                ],
                [
                    'nis' => '888802',
                    'nisn' => '0088888802',
                    'nama' => 'Siswa Import Excel 2',
                ],
            ],
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'imported_count' => 2,
                ],
            ]);

        $this->assertDatabaseHas('siswa', ['nis' => '888801', 'nama' => 'Siswa Import Excel 1']);
        $this->assertDatabaseHas('siswa', ['nis' => '888802', 'nama' => 'Siswa Import Excel 2']);
    }

    public function test_teacher_cannot_import_siswa()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $kelas = \App\Models\Kelas::first();

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/siswa/import', [
            'kelas_id' => $kelas->id,
            'students' => [
                [
                    'nis' => '888899',
                    'nisn' => '0088888899',
                    'nama' => 'Siswa Illegal Import',
                ],
            ],
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_can_get_semester_journal_sessions_without_future_dates()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();

        $response = $this->actingAs($guru, 'sanctum')->get('/api/jurnal/sesi-semester');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $data = $response->json('data');
        $this->assertArrayHasKey('sessions', $data);
        $this->assertArrayHasKey('total_sesi', $data);

        $today = date('Y-m-d');
        foreach ($data['sessions'] as $session) {
            $this->assertLessThanOrEqual($today, $session['tanggal'], 'Session tanggal must not be in the future');
        }
    }

    public function test_cannot_create_journal_with_future_date()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->first();
        $futureDate = date('Y-m-d', strtotime('+2 days'));

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/jurnal', [
            'jadwal_id' => $jadwal->id,
            'tanggal' => $futureDate,
            'materi' => 'Materi Masa Depan',
            'kegiatan' => 'Kegiatan Masa Depan',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_can_create_journal_with_past_date()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->first();
        $pastDate = date('Y-m-d', strtotime('-3 days'));

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/jurnal', [
            'jadwal_id' => $jadwal->id,
            'tanggal' => $pastDate,
            'materi' => 'Materi Pertemuan Lalu',
            'kegiatan' => 'Evaluasi KBM Lalu',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);
    }

    public function test_can_create_journal_with_photo_upload()
    {
        Storage::fake('public');

        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->first();
        $pastDate = date('Y-m-d', strtotime('-1 days'));

        $photo = UploadedFile::fake()->image('kegiatan_praktikum.jpg', 800, 600);

        $response = $this->actingAs($guru, 'sanctum')->post('/api/jurnal', [
            'jadwal_id' => $jadwal->id,
            'tanggal' => $pastDate,
            'materi' => 'Praktikum Mikrokontroler dengan Foto',
            'kegiatan' => 'Siswa merakit sirkuit IoT',
            'foto_kegiatan' => $photo,
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
            ]);

        $data = $response->json('data');
        $this->assertNotNull($data['foto_kegiatan']);
        $this->assertNotNull($data['foto_kegiatan_url']);
        Storage::disk('public')->assertExists($data['foto_kegiatan']);
    }

    public function test_can_update_journal_with_photo_upload()
    {
        Storage::fake('public');

        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->first();
        $pastDate = date('Y-m-d', strtotime('-2 days'));

        $jurnal = \App\Models\Jurnal::create([
            'guru_id' => $guru->id,
            'jadwal_id' => $jadwal->id,
            'tanggal' => $pastDate,
            'materi' => 'Materi Sebelum Update Foto',
            'kegiatan' => 'Kegiatan Sebelum Update',
        ]);

        $newPhoto = UploadedFile::fake()->image('kegiatan_update.png', 800, 600);

        $response = $this->actingAs($guru, 'sanctum')->post("/api/jurnal/{$jurnal->id}", [
            'tanggal' => $pastDate,
            'materi' => 'Materi Setelah Update Foto',
            'foto_kegiatan' => $newPhoto,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
            ]);

        $data = $response->json('data');
        $this->assertNotNull($data['foto_kegiatan']);
        Storage::disk('public')->assertExists($data['foto_kegiatan']);
    }

    public function test_cannot_upload_invalid_file_for_photo()
    {
        $guru = User::where('email', 'surya@smkn1abang.sch.id')->first();
        $jadwal = \App\Models\Jadwal::where('guru_id', $guru->id)->first();
        $pastDate = date('Y-m-d', strtotime('-1 days'));

        $pdf = UploadedFile::fake()->create('dokumen.pdf', 100, 'application/pdf');

        $response = $this->actingAs($guru, 'sanctum')->postJson('/api/jurnal', [
            'jadwal_id' => $jadwal->id,
            'tanggal' => $pastDate,
            'materi' => 'Materi Upload PDF Invalid',
            'foto_kegiatan' => $pdf,
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }
}


