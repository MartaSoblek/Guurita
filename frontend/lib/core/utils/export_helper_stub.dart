// Fallback stub for non-web platforms (e.g. CLI tests, mobile, desktop)

void downloadCsvImpl(String filename, String content) {
  // On mobile/desktop/tests, no-op or file system write if needed
}

void triggerBrowserPrintImpl() {
  // On non-web platforms, no-op
}
