<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('jurnal', function (Blueprint $table) {
            $table->id();
            $table->foreignId('guru_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('jadwal_id')->nullable()->constrained('jadwal')->nullOnDelete();
            $table->date('tanggal');
            $table->string('materi', 255);
            $table->text('kegiatan');
            $table->string('metode', 255)->nullable();
            $table->string('media', 255)->nullable();
            $table->text('kendala')->nullable();
            $table->text('tindak_lanjut')->nullable();
            $table->text('catatan')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('jurnal');
    }
};
