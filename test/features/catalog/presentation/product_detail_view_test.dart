import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<({FakeProductRepository products, FakeLinkLauncher launcher})> open(
    WidgetTester tester, {
    ProductDetail? detail,
    String slug = 'vestido-midi',
    Size size = const Size(390, 844),
  }) async {
    final fakes = registerAppFakes();
    if (detail != null) fakes.products.details[detail.slug] = detail;
    tester.setViewport(size);
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.productPath(slug)));
    await tester.pumpAndSettle();
    return (products: fakes.products, launcher: fakes.launcher);
  }

  for (final MapEntry(key: name, value: size) in testViewports.entries) {
    testWidgets('$name: detalhe sem overflow', (tester) async {
      await open(tester, detail: fakeDetail(), size: size);

      expect(find.text('Vestido Midi'), findsOneWidget);
      expect(find.text('Adicionar ao carrinho'), findsOneWidget);
      expect(find.text('Linho leve.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mostra cor e tamanho selecionados e "Última unidade"', (
    tester,
  ) async {
    await open(tester, detail: fakeDetail());

    expect(
      find.textContaining('Cor: Rosa', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Tamanho: P', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();

    expect(find.text('Última unidade!'), findsOneWidget);
  });

  testWidgets('quantidade sobe até o estoque', (tester) async {
    await open(tester, detail: fakeDetail()); // P tem 3

    final plus = find.byTooltip('Aumentar quantidade');
    await tester.ensureVisible(plus);
    for (var i = 0; i < 5; i++) {
      await tester.tap(plus);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Quantidade 3'), findsOneWidget);
  });

  testWidgets('tamanho esgotado mostra Avise-me e abre o WhatsApp', (
    tester,
  ) async {
    final fakes = await open(tester, detail: fakeDetail());

    await tester.tap(find.text('G'));
    await tester.pumpAndSettle();

    expect(find.text('Esgotado nessa combinação'), findsOneWidget);
    expect(find.text('Adicionar ao carrinho'), findsNothing);

    await tester.ensureVisible(find.text('Avise-me pelo WhatsApp'));
    await tester.tap(find.text('Avise-me pelo WhatsApp'));
    await tester.pump();

    expect(
      fakes.launcher.opened.single.queryParameters['text'],
      contains('Tam: G'),
    );
  });

  testWidgets('adicionar ao carrinho avisa que chega em breve (PR-06)', (
    tester,
  ) async {
    await open(tester, detail: fakeDetail());

    await tester.ensureVisible(find.text('Adicionar ao carrinho'));
    await tester.tap(find.text('Adicionar ao carrinho'));
    await tester.pump();

    expect(find.text('Carrinho chegando em breve!'), findsOneWidget);
  });

  testWidgets('slug inexistente: "Peça não encontrada" e volta para a loja', (
    tester,
  ) async {
    await open(tester, slug: 'nao-existe');

    expect(find.text('Peça não encontrada'), findsOneWidget);
    await tester.tap(find.text('Voltar para a loja'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.landing);
  });

  testWidgets('erro de rede mostra "Tentar novamente"', (tester) async {
    final fakes = registerAppFakes();
    fakes.products
      ..details['vestido-midi'] = fakeDetail()
      ..failure = const NetworkFailure();
    tester.setViewport(const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(AppRoutes.productPath('vestido-midi')));
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsOneWidget);
    fakes.products.failure = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Vestido Midi'), findsOneWidget);
  });
}
