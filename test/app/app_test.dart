import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/pages/design_system_view.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';
import 'package:joyjoy/features/catalog/presentation/views/landing_view.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

void main() {
  late InMemoryKeyValueStore storage;

  setUp(() => storage = registerAppFakes().storage);
  tearDown(Get.reset);

  Future<void> pumpJoyJoy(WidgetTester tester, {Size? size}) async {
    tester.setViewport(size ?? const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
  }

  testWidgets('abre na landing com as dependências globais', (tester) async {
    await pumpJoyJoy(tester);

    expect(find.byType(LandingView), findsOneWidget);
    expect(Get.find<Env>(), same(testEnv));
    expect(Get.find<KeyValueStore>(), same(storage));
  });

  testWidgets('botão de tema troca o tema do app e persiste', (tester) async {
    await pumpJoyJoy(tester);
    final controller = Get.find<ThemeController>();

    await tester.tap(find.byTooltip('Tema: automático'));
    await tester.pumpAndSettle();
    expect(controller.mode.value, ThemeMode.light);

    await tester.tap(find.byTooltip('Tema: claro'));
    await tester.pumpAndSettle();
    expect(controller.mode.value, ThemeMode.dark);
    expect(storage.read(ThemeController.storageKey), 'dark');

    final app = tester.widget<GetMaterialApp>(find.byType(GetMaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets(
    'rota desconhecida mostra "Página não encontrada" e volta para a loja',
    (tester) async {
      await pumpJoyJoy(tester);

      unawaited(Get.toNamed<void>('/rota-que-nao-existe'));
      await tester.pumpAndSettle();
      expect(find.text('Página não encontrada'), findsOneWidget);

      await tester.tap(find.text('Voltar para a loja'));
      await tester.pumpAndSettle();
      expect(find.byType(LandingView), findsOneWidget);
    },
  );

  for (final MapEntry(key: name, value: size) in testViewports.entries) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('$name ${mode.name}: /design renderiza sem overflow', (
        tester,
      ) async {
        await Get.find<ThemeController>().setMode(mode);
        tester.setViewport(size);
        await tester.pumpWidget(const JoyJoyApp());
        await tester.pump();

        unawaited(Get.toNamed<void>(AppRoutes.designSystem));
        // Skeletons animam em loop: avança o tempo em vez de pumpAndSettle.
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(DesignSystemView), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
