import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/utils/phone_format.dart';
import 'package:joyjoy/features/store/data/models/store_settings_model.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/presentation/widgets/store_footer.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  test('formatBrazilPhone', () {
    expect(formatBrazilPhone('5581986323686'), '(81) 98632-3686');
    expect(formatBrazilPhone('558132221111'), '(81) 3222-1111');
    expect(formatBrazilPhone('123'), '123');
  });

  test('links do rodapé são montados no app (nunca URL vinda do banco)', () {
    expect(
      StoreFooter.instagramUri('joyjoybrand_').toString(),
      'https://www.instagram.com/joyjoybrand_/',
    );
    expect(StoreFooter.instagramUri('https://evil.com'), isNull);
    expect(StoreFooter.instagramUri(null), isNull);

    final maps = StoreFooter.mapsUri(
      'Rua Professor Júlio Ferreira de Melo, 355 & Cia',
    );
    expect(maps.host, 'www.google.com');
    expect(
      maps.queryParameters['query'],
      'Rua Professor Júlio Ferreira de Melo, 355 & Cia',
    );
  });

  test('StoreSettingsModel lê Instagram, endereço e pagamentos', () {
    final s = StoreSettingsModel.fromJson(const {
      'store_name': 'JOYJOY',
      'whatsapp_number': '5581986323686',
      'greeting_message': 'Olá!',
      'is_open': true,
      'low_stock_threshold': 2,
      'instagram_handle': 'joyjoybrand_',
      'pickup_address': 'Rua X, 355',
      'payment_methods': ['card', 'pix'],
    });
    expect(s.instagramHandle, 'joyjoybrand_');
    expect(s.pickupAddress, 'Rua X, 355');
    expect(s.paymentMethods, ['card', 'pix']);
  });

  Future<void> openHome(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    StoreSettings? settings,
  }) async {
    registerAppFakes(
      store: settings == null ? null : FakeStoreRepository(settings),
    );
    tester.setViewport(size);
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: name, value: size) in testViewports.entries) {
    testWidgets('$name: rodapé na home com todas as seções e sem overflow', (
      tester,
    ) async {
      await openHome(tester, size: size);
      await tester.scrollUntilVisible(find.text('Endereço para retirada'), 300);

      expect(find.text('Atendimento ao cliente'), findsOneWidget);
      expect(find.text('(81) 98632-3686'), findsOneWidget);
      expect(find.text('Redes sociais'), findsOneWidget);
      expect(find.text('@joyjoybrand_'), findsOneWidget);
      expect(find.text('Formas de pagamento'), findsOneWidget);
      expect(find.text('Cartão'), findsOneWidget);
      expect(find.text('Pix'), findsOneWidget);
      expect(
        find.textContaining('Rua Professor Júlio Ferreira de Melo, 355'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tocar nos itens abre WhatsApp, Instagram e mapa', (
    tester,
  ) async {
    final fakes = registerAppFakes();
    tester.setViewport(const Size(1440, 900));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Endereço para retirada'), 300);

    await tester.tap(find.bySemanticsLabel('WhatsApp (81) 98632-3686'));
    await tester.tap(find.bySemanticsLabel('Instagram @joyjoybrand_'));
    await tester.tap(find.bySemanticsLabel(RegExp('Abrir no mapa')));
    await tester.pump();

    final hosts = fakes.launcher.opened.map((u) => u.host).toList();
    expect(hosts, ['wa.me', 'www.instagram.com', 'www.google.com']);
    expect(fakes.launcher.opened.first.path, '/5581986323686');
  });

  testWidgets('sem Instagram/endereço essas seções somem', (tester) async {
    await openHome(
      tester,
      settings: const StoreSettings(
        storeName: 'JOYJOY',
        whatsappNumber: '5581986323686',
        greetingMessage: 'Olá!',
        isOpen: true,
        lowStockThreshold: 2,
      ),
    );
    await tester.scrollUntilVisible(find.text('Atendimento ao cliente'), 300);

    expect(find.text('Redes sociais'), findsNothing);
    expect(find.text('Endereço para retirada'), findsNothing);
    expect(find.text('Formas de pagamento'), findsNothing);
  });

  testWidgets('rodapé também no fim do grid da seção', (tester) async {
    registerAppFakes(products: FakeProductRepository(fakeProducts(2)));
    tester.setViewport(const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.feminino));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Atendimento ao cliente'),
      300,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('@joyjoybrand_'), findsOneWidget);
  });
}
