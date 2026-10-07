import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/features/admin/auth/presentation/views/login_view.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_view.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<void> goTo(
    WidgetTester tester,
    String route, {
    Size size = const Size(390, 844),
  }) async {
    tester.setViewport(size);
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(route));
    await tester.pumpAndSettle();
  }

  Future<void> login(
    WidgetTester tester, {
    String password = 'senha-certa',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail'),
      'ana@joyjoy.com.br',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Senha'), password);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: size) in testViewports.entries) {
    testWidgets('$name: login sem overflow', (tester) async {
      registerAppFakes();
      await goTo(tester, AppRoutes.adminLogin, size: size);

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.text('Área da loja'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('/admin sem sessão → login; após entrar → painel', (
    tester,
  ) async {
    registerAppFakes();
    await goTo(tester, AppRoutes.admin);

    expect(find.byType(LoginView), findsOneWidget);
    await login(tester);

    expect(Get.currentRoute, AppRoutes.admin);
    expect(find.byType(DashboardView), findsOneWidget);
    expect(find.text('Pedidos aguardando confirmação'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('senha errada mostra erro genérico e não entra', (tester) async {
    registerAppFakes();
    await goTo(tester, AppRoutes.adminLogin);

    await login(tester, password: 'errada');

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    expect(Get.currentRoute, startsWith(AppRoutes.adminLogin));
  });

  testWidgets('campos vazios pedem e-mail e senha', (tester) async {
    registerAppFakes();
    await goTo(tester, AppRoutes.adminLogin);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe e-mail e senha.'), findsOneWidget);
  });

  testWidgets('volta para o pedido depois do login (next interno)', (
    tester,
  ) async {
    final orders = FakeOrderRepository()..orders['K7P2QX'] = fakeOrder();
    registerAppFakes(orders: orders);
    await goTo(tester, AppRoutes.adminLoginPath(next: '/pedido/K7P2QX'));

    await login(tester);

    expect(Get.currentRoute, '/pedido/K7P2QX');
  });

  testWidgets('next externo é ignorado (vai para o painel)', (tester) async {
    registerAppFakes();
    await goTo(
      tester,
      '${AppRoutes.adminLogin}?next=${Uri.encodeComponent('//evil.com')}',
    );

    await login(tester);

    expect(Get.currentRoute, AppRoutes.admin);
  });

  testWidgets('sessão de quem não é admin não abre o painel', (tester) async {
    registerAppFakes(auth: FakeAuthRepository(session: true, isAdmin: false));
    await goTo(tester, AppRoutes.admin);

    expect(find.byType(DashboardView), findsNothing);
    expect(Get.currentRoute, startsWith(AppRoutes.adminLogin));
  });

  for (final MapEntry(key: name, value: size) in testViewports.entries) {
    testWidgets('$name: painel sem overflow (menu lateral ou gaveta)', (
      tester,
    ) async {
      registerAppFakes(auth: FakeAuthRepository(session: true));
      await goTo(tester, AppRoutes.admin, size: size);

      expect(find.byType(DashboardView), findsOneWidget);
      expect(find.text('De onde vêm as visitas (7 dias)'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      if (size.width >= 600) {
        expect(find.byType(NavigationRail), findsOneWidget);
      } else {
        expect(find.byType(NavigationRail), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sem visitas mostra dica dos links com ?src=', (tester) async {
    registerAppFakes(auth: FakeAuthRepository(session: true));
    (Get.find<DashboardRepository>() as FakeDashboardRepository).stats =
        const AdminStats(
          pendingOrders: 0,
          activeProducts: 0,
          visitsBySource: {},
        );
    await goTo(tester, AppRoutes.admin);

    expect(find.textContaining('?src='), findsOneWidget);
  });

  testWidgets('Sair encerra a sessão e volta para a loja', (tester) async {
    final fakes = registerAppFakes(auth: FakeAuthRepository(session: true));
    await goTo(tester, AppRoutes.admin, size: const Size(1440, 900));

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();

    expect(fakes.auth.signOuts, 1);
    expect(Get.currentRoute, AppRoutes.landing);
  });

  testWidgets('link "Área da loja" no rodapé leva ao login', (tester) async {
    registerAppFakes();
    tester.setViewport(const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, 'Área da loja'),
      300,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Área da loja'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
  });
}
