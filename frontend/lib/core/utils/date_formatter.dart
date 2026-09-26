import 'package:intl/intl.dart';

class DateFormatter {
  static const List<String> hariIndo = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> bulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String getTodayFormatted() {
    final now = DateTime.now();
    final dayName = hariIndo[now.weekday - 1];
    final dayNum = now.day;
    final monthName = bulanIndo[now.month - 1];
    final year = now.year;
    return '$dayName, $dayNum $monthName $year';
  }

  static String getTodayDayName() {
    final now = DateTime.now();
    return hariIndo[now.weekday - 1];
  }

  static String formatIndonesianDate(String yyyyMmDd) {
    try {
      final dt = DateTime.parse(yyyyMmDd);
      final dayName = hariIndo[dt.weekday - 1];
      final dayNum = dt.day;
      final monthName = bulanIndo[dt.month - 1];
      final year = dt.year;
      return '$dayName, $dayNum $monthName $year';
    } catch (_) {
      return yyyyMmDd;
    }
  }

  static String formatShortDate(String yyyyMmDd) {
    try {
      final dt = DateTime.parse(yyyyMmDd);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return yyyyMmDd;
    }
  }

  static String getTodayDateIso() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }
}
