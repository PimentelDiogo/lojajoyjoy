import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_pages.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/config/app_constants.dart';
import 'package:joyjoy/core/theme/app_theme.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';

/// Raiz do app. Requer o `InitialBinding` já executado (ver `main.dart`).
class JoyJoyApp extends StatelessWidget {
  const JoyJoyApp({super.key});

  static const _locale = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: AppConstants.storeName,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.landing,
        getPages: AppPages.pages,
        unknownRoute: AppPages.notFound,
        locale: _locale,
        fallbackLocale: _locale,
        supportedLocales: const [_locale],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: theme.mode.value,
      ),
    );
  }
}
