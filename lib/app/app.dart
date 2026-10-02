import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:ondas_que_faltam/app/bindings/initial_binding.dart';
import 'package:ondas_que_faltam/app/routes/app_pages.dart';
import 'package:ondas_que_faltam/app/routes/app_routes.dart';
import 'package:ondas_que_faltam/core/config/app_constants.dart';
import 'package:ondas_que_faltam/core/config/env.dart';

class OndasApp extends StatelessWidget {
  const OndasApp({required this.env, super.key});

  final Env env;

  static const _locale = Locale('pt', 'BR');

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.storeName,
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(env: env),
      initialRoute: AppRoutes.landing,
      getPages: AppPages.pages,
      unknownRoute: AppPages.notFound,
      locale: _locale,
      fallbackLocale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Tema provisório: o design system pastel/dark chega no PR-02.
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF4A7B9),
      ),
    );
  }
}
