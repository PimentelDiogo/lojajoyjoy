import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:joyjoy/features/catalog/presentation/views/catalog_view.dart';
import 'package:joyjoy/features/catalog/presentation/views/product_detail_view.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<void> pumpAt(WidgetTester tester, String route, {Size? size}) async {
    tester.setViewport(size ?? const Size(390, 844));
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    if (route != AppRoutes.landing) {
      unawaited(Get.toNamed<void>(route));
      await tester.pumpAndSettle();
    }
  }

  group('Landing', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: blocos Feminino/Masculino e destaques sem overflow', (
        tester,
      ) async {
        registerAppFakes(
          products: FakeProductRepository([
            fakeProduct(1, featured: true),
            fakeProduct(2, featured: true, gender: Gender.masculino),
          ]),
        );
        await pumpAt(tester, AppRoutes.landing, size: size);

        expect(find.bySemanticsLabel('Ver moda feminino'), findsOneWidget);
        expect(find.bySemanticsLabel('Ver moda masculino'), findsOneWidget);
        expect(find.text('Destaques'), findsOneWidget);
        expect(find.text('Peça 1'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sem destaques a seção some', (tester) async {
      registerAppFakes(products: FakeProductRepository(fakeProducts(3)));
      await pumpAt(tester, AppRoutes.landing);

      expect(find.text('Destaques'), findsNothing);
    });

    testWidgets('tocar em Feminino abre o grid da seção', (tester) async {
      registerAppFakes();
      await pumpAt(tester, AppRoutes.landing);

      await tester.tap(find.bySemanticsLabel('Ver moda feminino'));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogView), findsOneWidget);
      expect(Get.currentRoute, AppRoutes.feminino);
    });

    testWidgets('recado da loja e aviso de loja fechada', (tester) async {
      registerAppFakes(
        store: FakeStoreRepository(
          const StoreSettings(
            storeName: 'JOYJOY',
            whatsappNumber: '5581986323686',
            greetingMessage: 'Olá!',
            isOpen: false,
            closedMessage: 'Voltamos na segunda!',
            announcement: 'Entregas em Recife',
            lowStockThreshold: 2,
          ),
        ),
      );
      await pumpAt(tester, AppRoutes.landing);

      expect(find.text('Voltamos na segunda!'), findsOneWidget);
      expect(find.text('Entregas em Recife'), findsOneWidget);
    });

    testWidgets('botão do WhatsApp abre wa.me da Ana com mensagem', (
      tester,
    ) async {
      final fakes = registerAppFakes();
      await pumpAt(tester, AppRoutes.landing);

      await tester.tap(find.byTooltip('Falar com a vendedora no WhatsApp'));
      await tester.pump();

      final uri = fakes.launcher.opened.single;
      expect(uri.host, 'wa.me');
      expect(uri.path, '/5581986323686');
      expect(uri.queryParameters['text'], contains('JOYJOY'));
    });

    testWidgets('número do WhatsApp inválido no banco: botão não aparece', (
      tester,
    ) async {
      registerAppFakes(
        store: FakeStoreRepository(
          const StoreSettings(
            storeName: 'JOYJOY',
            whatsappNumber: '81 98632-3686',
            greetingMessage: 'Olá!',
            isOpen: true,
            lowStockThreshold: 2,
          ),
        ),
      );
      await pumpAt(tester, AppRoutes.landing);

      expect(find.byTooltip('Falar com a vendedora no WhatsApp'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem configuração da loja, o botão do WhatsApp não aparece', (
      tester,
    ) async {
      registerAppFakes(store: FakeStoreRepository(null));
      await pumpAt(tester, AppRoutes.landing);

      expect(find.byTooltip('Falar com a vendedora no WhatsApp'), findsNothing);
    });
  });

  group('CatalogView', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: grid sem overflow', (tester) async {
        registerAppFakes(products: FakeProductRepository(fakeProducts(8)));
        await pumpAt(tester, AppRoutes.feminino, size: size);

        expect(find.text('Feminino'), findsWidgets);
        expect(find.text('Peça 0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('chips de categoria filtram', (tester) async {
      final fakes = registerAppFakes();
      await pumpAt(tester, AppRoutes.feminino);

      await tester.tap(find.widgetWithText(FilterChip, 'Vestidos'));
      await tester.pumpAndSettle();

      expect(fakes.products.queries.last.categoryId, 'c1');
    });

    testWidgets('ordenação pelo menu', (tester) async {
      final fakes = registerAppFakes();
      await pumpAt(tester, AppRoutes.masculino);

      await tester.tap(find.byTooltip('Ordenar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menor preço').last);
      await tester.pumpAndSettle();

      expect(fakes.products.queries.last.sort.name, 'priceAsc');
      expect(fakes.products.queries.last.gender, Gender.masculino);
    });

    testWidgets('rolar até o fim carrega mais peças', (tester) async {
      final fakes = registerAppFakes(
        products: FakeProductRepository(fakeProducts(45)),
      );
      await pumpAt(tester, AppRoutes.feminino);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await tester.pumpAndSettle();

      expect(fakes.products.queries.where((q) => q.offset > 0), isNotEmpty);
      final controller = Get.find<CatalogController>(tag: Gender.feminino.name);
      expect(controller.products.length, greaterThan(20));
    });

    testWidgets('seção vazia mostra mensagem', (tester) async {
      registerAppFakes(products: FakeProductRepository([]));
      await pumpAt(tester, AppRoutes.feminino);

      expect(find.text('Nenhuma peça por aqui ainda'), findsOneWidget);
    });

    testWidgets('erro mostra "Tentar novamente" e recarrega', (tester) async {
      final fakes = registerAppFakes();
      fakes.products.failure = const NetworkFailure();
      await pumpAt(tester, AppRoutes.feminino);

      expect(find.text('Tentar novamente'), findsOneWidget);
      fakes.products.failure = null;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Peça 0'), findsOneWidget);
    });

    testWidgets('tocar numa peça abre /produto/:slug', (tester) async {
      final fakes = registerAppFakes();
      fakes.products.details['peca-0'] = fakeDetail(slug: 'peca-0');
      await pumpAt(tester, AppRoutes.feminino);

      await tester.tap(find.text('Peça 0'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/produto/peca-0');
      expect(find.byType(ProductDetailView), findsOneWidget);
    });
  });
}
