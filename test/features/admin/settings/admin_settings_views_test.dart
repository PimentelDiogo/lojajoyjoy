import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/features/admin/settings/presentation/admin_settings_view.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<FakeAdminSettingsRepository> open(WidgetTester tester) async {
    final fakes = registerAppFakes(auth: FakeAuthRepository(session: true));
    tester.setViewport(const Size(1440, 900));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.adminSettings));
    await tester.pumpAndSettle();
    return fakes.adminSettings;
  }

  testWidgets('loja aberta: mostra os 3 prazos', (tester) async {
    await open(tester);

    expect(find.byType(AdminSettingsView), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('1 hora'), findsOneWidget);
    expect(find.text('Reabrir a loja'), findsNothing);
  });

  testWidgets('menu "Configurações" leva até lá', (tester) async {
    final fakes = registerAppFakes(auth: FakeAuthRepository(session: true));
    tester.setViewport(const Size(1440, 900));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.admin));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.adminSettings);
    expect(fakes.adminSettings.startedWith, isEmpty);
  });

  testWidgets('inicia a auditoria de 30 min', (tester) async {
    final repo = await open(tester);

    await tester.tap(find.text('30 min'));
    // _Active tem um Timer.periodic: pump() em vez de pumpAndSettle().
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.startedWith, [30]);
    expect(find.textContaining('Em auditoria'), findsOneWidget);
    expect(find.text('Reabrir a loja'), findsOneWidget);
    expect(find.text('15 min'), findsNothing);
  });

  testWidgets('reabre a loja a partir do modo auditoria', (tester) async {
    final repo = await open(tester);
    await tester.tap(find.text('15 min'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Reabrir a loja'), findsOneWidget);

    await tester.tap(find.text('Reabrir a loja'));
    await tester.pumpAndSettle();

    expect(repo.stopCalls, 1);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('Reabrir a loja'), findsNothing);
  });

  testWidgets('erro do servidor aparece e não troca de estado', (
    tester,
  ) async {
    final repo = await open(tester);
    repo.failure = const ServerFailure('Não foi possível salvar agora.');

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível salvar agora.'), findsOneWidget);
    expect(find.text('Reabrir a loja'), findsNothing);
  });
}
