import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_view.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  group('PasswordRules', () {
    test('mínimo 10, letras e números, confirmação igual', () {
      expect(PasswordRules.validate('curta1', 'curta1'), contains('10'));
      expect(
        PasswordRules.validate('1234567890', '1234567890'),
        contains('letras'),
      );
      expect(
        PasswordRules.validate('abcdefghij', 'abcdefghij'),
        contains('números'),
      );
      expect(
        PasswordRules.validate('joyjoy2026!', 'joyjoy2026?'),
        'As senhas não são iguais.',
      );
      expect(PasswordRules.validate('joyjoy2026!', 'joyjoy2026!'), isNull);
    });

    test(
      'RequestPasswordReset recusa e-mail inválido sem chamar o servidor',
      () async {
        final repo = FakeAuthRepository();
        final reset = RequestPasswordReset(
          repo,
          redirectTo: Uri.parse('https://x/'),
        );

        expect((await reset('ana')).isFailure, isTrue);
        expect(repo.resetRequests, isEmpty);
        expect((await reset(' ana@joyjoy.com.br ')).isSuccess, isTrue);
        expect(repo.resetRequests.single.$1, 'ana@joyjoy.com.br');
      },
    );
  });

  Future<void> goTo(WidgetTester tester, String route) async {
    tester.setViewport(const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(route));
    await tester.pumpAndSettle();
  }

  testWidgets('"Esqueci minha senha" envia o link para /admin/nova-senha', (
    tester,
  ) async {
    final fakes = registerAppFakes();
    await goTo(tester, AppRoutes.adminLogin);

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'ana@joyjoy.com.br',
    );
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    final (email, redirect) = fakes.auth.resetRequests.single;
    expect(email, 'ana@joyjoy.com.br');
    expect(redirect.path, endsWith('/admin/nova-senha'));
    expect(find.textContaining('Se este e-mail tiver acesso'), findsOneWidget);
  });

  testWidgets('nova senha sem sessão (link vencido) orienta a pedir outro', (
    tester,
  ) async {
    registerAppFakes();
    await goTo(tester, AppRoutes.adminNewPassword);

    expect(find.text('Link inválido ou expirado'), findsOneWidget);
    await tester.tap(find.text('Ir para o login'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.adminLogin);
  });

  testWidgets('nova senha: valida, salva e entra no painel', (tester) async {
    final fakes = registerAppFakes(auth: FakeAuthRepository(session: true));
    await goTo(tester, AppRoutes.adminNewPassword);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nova senha'),
      'curta',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Repita a nova senha'),
      'curta',
    );
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pelo menos 10'), findsWidgets);
    expect(fakes.auth.passwordUpdates, isEmpty);

    await tester.enterText(
      find.widgetWithText(TextField, 'Nova senha'),
      'joyjoy2026forte',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Repita a nova senha'),
      'joyjoy2026forte',
    );
    await tester.tap(find.text('Salvar nova senha'));
    await tester.pumpAndSettle();

    expect(fakes.auth.passwordUpdates, ['joyjoy2026forte']);
    expect(Get.currentRoute, AppRoutes.admin);
    expect(find.byType(DashboardView), findsOneWidget);
  });

  test('UpdatePassword não chama o servidor se a regra falhar', () async {
    final repo = FakeAuthRepository(session: true);
    final result = await UpdatePassword(repo)((
      password: 'abc',
      confirmation: 'abc',
    ));
    expect(result, isA<Failed<void>>());
    expect(repo.passwordUpdates, isEmpty);
  });
}
