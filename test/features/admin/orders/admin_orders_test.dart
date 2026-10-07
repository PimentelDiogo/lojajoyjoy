import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/features/admin/auth/presentation/views/login_view.dart';
import 'package:joyjoy/features/admin/orders/presentation/admin_orders_view.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/entities/order_failure.dart';
import 'package:joyjoy/features/order/presentation/widgets/order_admin_panel.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<FakeOrderRepository> openOrder(
    WidgetTester tester, {
    bool admin = true,
    OrderStatus status = OrderStatus.pending,
    Size size = const Size(390, 844),
  }) async {
    final orders = FakeOrderRepository()
      ..orders['K7P2QX'] = fakeOrder(status: status, customerName: 'Maria');
    registerAppFakes(
      orders: orders,
      auth: FakeAuthRepository(session: admin),
    );
    tester.setViewport(size);
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.orderPath('K7P2QX')));
    await tester.pumpAndSettle();
    return orders;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('link do pedido', () {
    testWidgets('cliente: sem ações da loja, com "Sou a Ana, entrar"', (
      tester,
    ) async {
      final orders = await openOrder(tester, admin: false);

      expect(find.byType(OrderAdminPanel), findsNothing);
      expect(find.text('Confirmar venda'), findsNothing);

      await tapText(tester, 'Sou a Ana, entrar');
      expect(find.byType(LoginView), findsOneWidget);
      expect(
        Get.currentRoute,
        AppRoutes.adminLoginPath(next: '/pedido/K7P2QX'),
      );
      expect(orders.actions, isEmpty);
    });

    testWidgets('Ana entra pelo link e volta para o pedido com as ações', (
      tester,
    ) async {
      await openOrder(tester, admin: false);
      await tapText(tester, 'Sou a Ana, entrar');

      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'ana@joyjoy.com.br',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Senha'),
        'senha-certa',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/pedido/K7P2QX');
      expect(find.text('Confirmar venda'), findsOneWidget);
      expect(find.text('Sou a Ana, entrar'), findsNothing);
    });

    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: painel da Ana sem overflow', (tester) async {
        await openOrder(tester, size: size);

        expect(find.byType(OrderAdminPanel), findsOneWidget);
        expect(find.text('Cliente: Maria'), findsOneWidget);
        expect(find.text('Confirmar venda'), findsOneWidget);
        expect(find.text('Cancelar pedido'), findsOneWidget);
        expect(find.text('Falar com a Ana sobre este pedido'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('confirmar pede confirmação e atualiza o status', (
      tester,
    ) async {
      final orders = await openOrder(tester);

      await tapText(tester, 'Confirmar venda');
      expect(find.text('Confirmar a venda?'), findsOneWidget);
      expect(find.textContaining('3 peças'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Confirmar venda'),
        ),
      );
      await tester.pumpAndSettle();

      expect(orders.actions, ['confirm:K7P2QX']);
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Venda confirmada. Estoque baixado.'), findsOneWidget);
      expect(find.text('Confirmar venda'), findsNothing);
      expect(find.text('Cancelar pedido'), findsOneWidget);
    });

    testWidgets('"Voltar" no diálogo não faz nada', (tester) async {
      final orders = await openOrder(tester);

      await tapText(tester, 'Cancelar pedido');
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(orders.actions, isEmpty);
    });

    testWidgets('cancelar confirmado avisa que o estoque volta', (
      tester,
    ) async {
      final orders = await openOrder(tester, status: OrderStatus.confirmed);

      expect(find.text('Confirmar venda'), findsNothing);
      await tapText(tester, 'Cancelar pedido');
      expect(find.textContaining('o estoque das peças volta'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar pedido'));
      await tester.pumpAndSettle();

      expect(orders.actions, ['cancel:K7P2QX']);
      expect(find.text('Cancelado'), findsOneWidget);
      expect(find.text('Cancelar pedido'), findsNothing);
    });

    testWidgets('sem estoque: mostra a peça e o pedido continua pendente', (
      tester,
    ) async {
      final orders = await openOrder(tester);
      orders.actionFailure = OrderFailure.fromActionCode(
        'insufficient_stock',
        detail: 'Camisa Oxford · Tam G · Azul (tem 1, pedido 2)',
      );

      await tapText(tester, 'Confirmar venda');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Confirmar venda'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Camisa Oxford · Tam G · Azul'),
        findsOneWidget,
      );
      expect(find.text('Aguardando confirmação'), findsOneWidget);
    });
  });

  group('/admin/pedidos', () {
    Future<void> openList(
      WidgetTester tester, {
      Size size = const Size(1440, 900),
    }) async {
      registerAppFakes(auth: FakeAuthRepository(session: true));
      tester.setViewport(size);
      await tester.pumpWidget(const JoyJoyApp());
      await tester.pumpAndSettle();
      unawaited(Get.toNamed<void>(AppRoutes.adminOrders));
      await tester.pumpAndSettle();
    }

    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: lista sem overflow, abre em "Aguardando"', (
        tester,
      ) async {
        await openList(tester, size: size);

        expect(find.byType(AdminOrdersView), findsOneWidget);
        expect(find.text('Aguardando (2)'), findsOneWidget);
        expect(find.text('#AAA111'), findsOneWidget);
        expect(find.text('#DDD444'), findsOneWidget);
        expect(find.text('#BBB222'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('filtros e abrir o pedido', (tester) async {
      await openList(tester);

      await tester.tap(find.text('Todos (4)'));
      await tester.pumpAndSettle();
      expect(find.text('#BBB222'), findsOneWidget);
      expect(find.text('#CCC333'), findsOneWidget);

      await tester.tap(find.text('Confirmados (1)'));
      await tester.pumpAndSettle();
      expect(find.text('#AAA111'), findsNothing);

      await tester.tap(find.text('#BBB222'));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, '/pedido/BBB222');
    });

    testWidgets('menu "Pedidos" leva à lista', (tester) async {
      await openList(tester);
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pedidos'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.adminOrders);
    });
  });
}
