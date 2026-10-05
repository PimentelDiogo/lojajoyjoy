import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/entities/order_failure.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<InMemoryKeyValueStore> storageWith(List<CartItem> items) async {
    final kv = InMemoryKeyValueStore();
    var cart = Cart.empty;
    for (final item in items) {
      cart = cart.add(item).$1;
    }
    await CartRepositoryImpl(CartLocalDataSourceImpl(kv)).save(cart);
    return kv;
  }

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

  Future<void> submit(WidgetTester tester) async {
    final button = find.text('Enviar pedido pelo WhatsApp');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('Checkout', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: formulário e resumo sem overflow', (tester) async {
        final kv = await storageWith([
          fakeCartItem('v1', quantity: 2, note: 'barra'),
        ]);
        registerAppFakes(storage: kv);
        await goTo(tester, AppRoutes.checkout, size: size);

        expect(find.text('Finalizar pedido'), findsOneWidget);
        expect(find.text('2× Peça v1'), findsOneWidget);
        expect(find.text('Retirar com a Ana'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('carrinho → Finalizar abre /finalizar', (tester) async {
      final kv = await storageWith([fakeCartItem('v1')]);
      registerAppFakes(storage: kv);
      await goTo(tester, AppRoutes.cart);

      await tester.tap(find.text('Finalizar no WhatsApp'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.checkout);
    });

    testWidgets(
      'enviar: cria no servidor, limpa o carrinho, abre a página do pedido e o WhatsApp',
      (tester) async {
        final kv = await storageWith([
          fakeCartItem('v1', quantity: 2, note: 'barra'),
        ]);
        final fakes = registerAppFakes(storage: kv);
        await goTo(tester, AppRoutes.checkout);

        await tester.enterText(
          find.widgetWithText(TextField, 'Seu nome (opcional)'),
          'Maria',
        );
        await tester.tap(find.text('Retirar com a Ana'));
        await tester.tap(find.text('Pix'));
        await tester.pumpAndSettle();
        await submit(tester);

        final request = fakes.orders.requests.single;
        expect(
          request.lines.single,
          const CheckoutLine(variantId: 'v1', quantity: 2, note: 'barra'),
        );
        expect(request.customerName, 'Maria');
        expect(request.deliveryMethod, DeliveryMethod.pickup);
        expect(request.paymentMethod, PaymentMethod.pix);
        expect(request.source, 'instagram'); // ?src=instagram no fake
        expect(request.sessionId, hasLength(36));

        expect(fakes.cart.cart.value.isEmpty, isTrue);
        expect(Get.currentRoute, '/pedido/K7P2QX');
        expect(find.textContaining('Pedido enviado!'), findsOneWidget);

        final uri = fakes.launcher.opened.single;
        expect(uri.host, 'wa.me');
        expect(uri.path, '/5581986323686');
        final text = uri.queryParameters['text']!;
        expect(text, contains('Pedido #K7P2QX'));
        expect(
          text,
          contains('💰 Total: ${brl('449,70')}'),
        ); // total DO SERVIDOR
        expect(text, contains('http://localhost:8080/pedido/K7P2QX'));
      },
    );

    testWidgets('sem estoque: mostra a peça com problema e mantém o carrinho', (
      tester,
    ) async {
      final kv = await storageWith([fakeCartItem('v1')]);
      final orders = FakeOrderRepository()
        ..createResult = Failed(
          OrderFailure.fromCode('insufficient_stock', variantId: 'v1'),
        );
      final fakes = registerAppFakes(storage: kv, orders: orders);
      await goTo(tester, AppRoutes.checkout);

      await submit(tester);

      expect(
        find.textContaining('não tem mais essa quantidade'),
        findsOneWidget,
      );
      expect(find.textContaining('Peça v1 (Tam M, Rosa)'), findsOneWidget);
      expect(fakes.cart.cart.value.isEmpty, isFalse);
      expect(fakes.launcher.opened, isEmpty);
      expect(Get.currentRoute, AppRoutes.checkout);
    });

    testWidgets('loja fechada: não envia', (tester) async {
      final kv = await storageWith([fakeCartItem('v1')]);
      final fakes = registerAppFakes(
        storage: kv,
        store: FakeStoreRepository(
          const StoreSettings(
            storeName: 'JOYJOY',
            whatsappNumber: '5581986323686',
            greetingMessage: 'Olá!',
            isOpen: false,
            closedMessage: 'Voltamos segunda!',
            lowStockThreshold: 2,
          ),
        ),
      );
      await goTo(tester, AppRoutes.checkout);

      expect(find.text('Enviar pedido pelo WhatsApp'), findsNothing);
      expect(find.text('Voltamos segunda!'), findsOneWidget);
      expect(fakes.orders.requests, isEmpty);
    });

    testWidgets('carrinho vazio em /finalizar', (tester) async {
      registerAppFakes();
      await goTo(tester, AppRoutes.checkout);

      expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    });
  });

  group('Página do pedido', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: resumo do pedido sem overflow', (tester) async {
        final orders = FakeOrderRepository()..orders['K7P2QX'] = fakeOrder();
        registerAppFakes(orders: orders);
        await goTo(tester, AppRoutes.orderPath('K7P2QX'), size: size);

        expect(find.text('Pedido #K7P2QX'), findsOneWidget);
        expect(find.text('Aguardando confirmação'), findsOneWidget);
        expect(find.text('2× Camisa Oxford'), findsOneWidget);
        expect(find.text('Entrega: Retirar com a Ana'), findsOneWidget);
        expect(find.textContaining('Pedido enviado!'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('código em minúsculas funciona', (tester) async {
      final orders = FakeOrderRepository()..orders['K7P2QX'] = fakeOrder();
      registerAppFakes(orders: orders);
      await goTo(tester, '/pedido/k7p2qx');

      expect(find.text('Pedido #K7P2QX'), findsOneWidget);
    });

    testWidgets('código inexistente', (tester) async {
      registerAppFakes();
      await goTo(tester, AppRoutes.orderPath('ZZZZZZ'));

      expect(find.text('Pedido não encontrado'), findsOneWidget);
    });

    testWidgets('falar com a Ana cita o pedido', (tester) async {
      final orders = FakeOrderRepository()..orders['K7P2QX'] = fakeOrder();
      final fakes = registerAppFakes(orders: orders);
      await goTo(tester, AppRoutes.orderPath('K7P2QX'));

      final button = find.text('Falar com a Ana sobre este pedido');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      expect(
        fakes.launcher.opened.single.queryParameters['text'],
        'Olá! Sobre o pedido #K7P2QX',
      );
    });
  });
}
