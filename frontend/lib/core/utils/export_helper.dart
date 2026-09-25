import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart';

class ExportHelper {
  static void downloadCsv(String filename, String content) {
    downloadCsvImpl(filename, content);
  }

  static void triggerPrint() {
    triggerBrowserPrintImpl();
  }
}
