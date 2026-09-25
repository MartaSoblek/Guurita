import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/responsive/responsive_layout.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../data/models/journal_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/services/journal_service.dart';

class JournalDetailView extends StatefulWidget {
  final JournalModel journal;

  const JournalDetailView({super.key, required this.journal});

  @override
  State<JournalDetailView> createState() => _JournalDetailViewState();
}

class _JournalDetailViewState extends State<JournalDetailView> {
  final JournalService _journalService = JournalService();
  late JournalModel _currentJournal;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _currentJournal = widget.journal;
    _checkAndFetchAttendance();
  }

  Future<void> _checkAndFetchAttendance() async {
    if (_currentJournal.kehadiran == null || _currentJournal.kehadiran!.isEmpty) {
      setState(() {
        _isLoadingStudents = true;
      });
      try {
        final detailed = await _journalService.getJournalById(_currentJournal.id);
        if (detailed != null && mounted) {
          setState(() {
            _currentJournal = detailed;
          });
        }
      } catch (_) {
        // safe fallback
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingStudents = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = _currentJournal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Jurnal Mengajar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: ResponsiveContainer(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Summary Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${journal.namaKelas ?? "-"} • ${journal.namaMapel ?? "-"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatIndonesianDate(journal.tanggal),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        journal.materi,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guru Pengampu: ${journal.namaGuru ?? "I Made Surya, S.Kom"} • Waktu: ${journal.jamMulai ?? "07:30"} - ${journal.jamSelesai ?? "09:00"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Presensi Recap Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rekapitulasi Kehadiran Siswa',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          Text(
                            'Total Siswa: ${journal.totalSiswa}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _counterBox(
                              'Hadir',
                              '${journal.totalHadir}',
                              AppColors.success,
                              AppColors.successSubtle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _counterBox(
                              'Izin',
                              '${journal.totalIzin}',
                              Colors.blue.shade700,
                              Colors.blue.shade50,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _counterBox(
                              'Sakit',
                              '${journal.totalSakit}',
                              Colors.amber.shade800,
                              Colors.amber.shade50,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _counterBox(
                              'Alpa',
                              '${journal.totalAlpa}',
                              AppColors.error,
                              AppColors.errorSubtle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Daftar Kehadiran Siswa
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daftar Presensi Siswa',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMain,
                            ),
                          ),
                          if (_isLoadingStudents)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildAttendanceList(journal.kehadiran),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Details Content Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rincian Kegiatan Pembelajaran',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sectionDetail('Kegiatan Pembelajaran', journal.kegiatan.isNotEmpty ? journal.kegiatan : '-'),
                      const Divider(height: 28),
                      _sectionDetail('Metode Pembelajaran', journal.metode ?? '-'),
                      const Divider(height: 28),
                      _sectionDetail('Media Pembelajaran', journal.media ?? '-'),
                      const Divider(height: 28),
                      _sectionDetail('Kendala Pembelajaran', journal.kendala ?? 'Tidak ada kendala'),
                      const Divider(height: 28),
                      _sectionDetail('Tindak Lanjut / Solusi', journal.tindakLanjut ?? '-'),
                      const Divider(height: 28),
                      _sectionDetail('Catatan Tambahan', journal.catatan ?? '-'),
                    ],
                  ),
                ),
              ),

              // 5. Foto Dokumentasi Kegiatan Pembelajaran
              if (journal.hasFotoKegiatan) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Foto Dokumentasi Kegiatan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Bukti dokumentasi pelaksanaan KBM di kelas / laboratorium',
                                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () {
                            _showImagePreviewDialog(
                              context,
                              url: (journal.fotoKegiatanUrl ?? journal.fotoKegiatan)!,
                              title: 'Dokumentasi: ${journal.materi}',
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: double.infinity,
                                  height: 260,
                                  color: Colors.grey.shade100,
                                  child: Image.network(
                                    AppImageHelper.resolveImageUrl(journal.fotoKegiatanUrl ?? journal.fotoKegiatan) ??
                                        (journal.fotoKegiatanUrl ?? journal.fotoKegiatan)!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 260,
                                    errorBuilder: (ctx, err, stack) => Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey.shade400),
                                          const SizedBox(height: 6),
                                          Text('Gagal memuat foto',
                                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                    },
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Klik untuk perbesar',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceList(List<AttendanceModel>? list) {
    if (_isLoadingStudents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Memuat rincian presensi siswa...', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    if (list == null || list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Data rincian nama siswa tidak tersedia.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final att = list[index];
        final isPresent = att.status == 'Hadir';

        Color badgeColor;
        Color badgeBg;
        if (att.status == 'Hadir') {
          badgeColor = AppColors.success;
          badgeBg = AppColors.successSubtle;
        } else if (att.status == 'Izin') {
          badgeColor = Colors.blue.shade700;
          badgeBg = Colors.blue.shade50;
        } else if (att.status == 'Sakit') {
          badgeColor = Colors.amber.shade800;
          badgeBg = Colors.amber.shade50;
        } else {
          badgeColor = AppColors.error;
          badgeBg = AppColors.errorSubtle;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isPresent ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      att.namaSiswa,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain),
                    ),
                    Text(
                      'NIS: ${att.nis}${att.keterangan != null && att.keterangan!.isNotEmpty ? " • Ket: ${att.keterangan}" : ""}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  att.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionDetail(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _counterBox(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreviewDialog(
    BuildContext context, {
    required String url,
    String? title,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.image_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title ?? 'Foto Dokumentasi Kegiatan',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                    child: Image.network(
                      AppImageHelper.resolveImageUrl(url) ?? url,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Center(
                        child: Text('Gagal memuat foto', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
