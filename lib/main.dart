import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/theme_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/bookmark_controller.dart';
import 'controllers/hadith_search_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/social_controller.dart';
import 'controllers/notification_controller.dart';
import 'ui/splash_screen.dart';
import 'ui/auth_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zzewjcymqynibjujrpej.supabase.co',
    anonKey: 'sb_publishable_cPzTjgzVkHWhjODfCI56Vg_auqS1M0X',
  );

  // Initialize persistence-dependent controllers
  Get.put(ThemeController(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(BookmarkController(), permanent: true);
  Get.put(HadithSearchController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(SocialController(), permanent: true);
  Get.put(NotificationController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final authController = Get.find<AuthController>();

    return GetMaterialApp(
      title: 'Hadith Premium',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.whiteGolden,
      darkTheme: AppTheme.blackGolden,
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Obx(() {
        if (authController.user.value == null) {
          return const AuthScreen();
        }
        return SplashScreen();
      }),
    );
  }
}
