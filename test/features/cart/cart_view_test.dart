import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
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

  Future<void> openCart(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    InMemoryKeyValueStore? storage,
    FakeStoreRepository? store,
  }) async {
    registerAppFakes(storage: storage, store: store);
    tester.setViewport(size);
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.cart));
    await tester.pumpAndSettle();
  }

  testWidgets('vazio: mensagem e "Ver peças"', (tester) async {
    await openCart(tester);

    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    await tester.tap(find.text('Ver peças'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.landing);
  });

  for (final MapEntry(key: name, value: size) in testViewports.entries) {
    testWidgets('$name: itens e total sem overflow', (tester) async {
      final kv = await storageWith([
        fakeCartItem('v1', quantity: 2, price: 189.9, note: 'barra 2 cm'),
        fakeCartItem('v2', price: 59.9),
      ]);
      await openCart(tester, size: size, storage: kv);

      expect(find.text('Seu carrinho (3 peças)'), findsOneWidget);
      expect(find.text('Subtotal (3 peças)'), findsOneWidget);
      expect(find.text(brl('439,70')), findsOneWidget);
      expect(find.text('barra 2 cm'), findsOneWidget);
      expect(find.text('Finalizar no WhatsApp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('aumentar quantidade atualiza o total e respeita o estoque', (
    tester,
  ) async {
    final kv = await storageWith([fakeCartItem('v1', max: 2)]);
    await openCart(tester, storage: kv);

    final plus = find.byTooltip('Aumentar quantidade');
    await tester.tap(plus);
    await tester.pumpAndSettle();
    await tester.tap(plus); // já no limite (2)
    await tester.pumpAndSettle();

    expect(find.text('Subtotal (2 peças)'), findsOneWidget);
    expect(find.text(brl('200,00')), findsWidgets);
  });

  testWidgets('remover mostra "Desfazer" e devolve a peça', (tester) async {
    final kv = await storageWith([fakeCartItem('v1'), fakeCartItem('v2')]);
    await openCart(tester, storage: kv);

    await tester.tap(find.byTooltip('Remover Peça v1'));
    await tester.pumpAndSettle();
    expect(find.text('Peça v1'), findsNothing);
    expect(find.text('Peça v1 removida do carrinho'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('Peça v1'), findsOneWidget);
  });

  testWidgets('observação digitada é salva no item', (tester) async {
    final kv = await storageWith([fakeCartItem('v1')]);
    await openCart(tester, storage: kv);

    await tester.enterText(find.byType(TextField), 'sem etiqueta');
    await tester.pumpAndSettle();

    final saved = CartRepositoryImpl(CartLocalDataSourceImpl(kv)).load();
    expect(saved.items.single.note, 'sem etiqueta');
  });

  testWidgets('loja fechada bloqueia o finalizar e mostra o aviso', (
    tester,
  ) async {
    final kv = await storageWith([fakeCartItem('v1')]);
    await openCart(
      tester,
      storage: kv,
      store: FakeStoreRepository(
        const StoreSettings(
          storeName: 'JOYJOY',
          whatsappNumber: '5581986323686',
          greetingMessage: 'Olá!',
          isOpen: false,
          closedMessage: 'Voltamos na segunda!',
          lowStockThreshold: 2,
        ),
      ),
    );

    expect(find.text('Finalizar no WhatsApp'), findsNothing);
    expect(find.text('Voltamos na segunda!'), findsWidgets);
  });

  testWidgets('contador do header mostra as peças salvas', (tester) async {
    final kv = await storageWith([fakeCartItem('v1', quantity: 3)]);
    registerAppFakes(storage: kv);
    tester.setViewport(const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Carrinho, 3 peças'), findsOneWidget);
    await tester.tap(find.byTooltip('Carrinho, 3 peças'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.cart);
  });
}
