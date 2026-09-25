import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/constants/app_constants.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/app_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStorage.init();

  runApp(const GuritaApp());
}

class GuritaApp extends StatelessWidget {
  const GuritaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appFullTitle,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
