import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:ondas_que_faltam/app/routes/app_pages.dart';
import 'package:ondas_que_faltam/app/routes/app_routes.dart';
import 'package:ondas_que_faltam/core/config/app_constants.dart';
import 'package:ondas_que_faltam/core/theme/app_theme.dart';
import 'package:ondas_que_faltam/core/theme/theme_controller.dart';

/// Raiz do app. Requer o `InitialBinding` já executado (ver `main.dart`).
class OndasApp extends StatelessWidget {
  const OndasApp({super.key});

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
