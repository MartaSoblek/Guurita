<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up()
    {
        DB::statement('ALTER TABLE jurnal MODIFY kegiatan TEXT NULL');
    }

    public function down()
    {
        DB::statement("UPDATE jurnal SET kegiatan = '-' WHERE kegiatan IS NULL");
        DB::statement('ALTER TABLE jurnal MODIFY kegiatan TEXT NOT NULL');
    }
};
