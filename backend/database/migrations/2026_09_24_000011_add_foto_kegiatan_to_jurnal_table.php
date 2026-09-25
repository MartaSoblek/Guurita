<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::table('jurnal', function (Blueprint $table) {
            $table->string('foto_kegiatan', 255)->nullable()->after('catatan');
        });
    }

    public function down()
    {
        Schema::table('jurnal', function (Blueprint $table) {
            $table->dropColumn('foto_kegiatan');
        });
    }
};
