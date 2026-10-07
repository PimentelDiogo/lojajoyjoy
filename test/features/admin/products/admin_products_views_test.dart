import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/app.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/features/admin/products/presentation/views/admin_products_view.dart';
import 'package:joyjoy/features/admin/products/presentation/views/product_form_view.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Future<FakeAdminProductRepository> open(
    WidgetTester tester,
    String route, {
    Size size = const Size(1440, 900),
    FakeAdminProductRepository? repo,
  }) async {
    final fakes = registerAppFakes(
      auth: FakeAuthRepository(session: true),
      adminProducts: repo,
    );
    tester.setViewport(size);
    await tester.pumpWidget(const JoyJoyApp());
    await tester.pumpAndSettle();
    unawaited(Get.toNamed<void>(route));
    await tester.pumpAndSettle();
    return fakes.adminProducts;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  group('lista de peças', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: sem overflow', (tester) async {
        await open(tester, AppRoutes.adminProducts, size: size);

        expect(find.byType(AdminProductsView), findsOneWidget);
        expect(find.text('Peça 1'), findsOneWidget);
        expect(find.text('2 peças'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('menu "Produtos" leva à lista', (tester) async {
      await open(tester, AppRoutes.admin);

      await tester.tap(find.text('Produtos'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.adminProducts);
    });

    testWidgets('busca ignora acento e filtro separa ocultas', (tester) async {
      final repo = FakeAdminProductRepository(
        products: [
          fakeAdminProduct(1).copyWith(),
          fakeAdminProduct(2, active: false, category: 'Calças'),
        ],
      );
      await open(tester, AppRoutes.adminProducts, repo: repo);

      await tester.enterText(field('Buscar peça'), 'calca');
      await tester.pump();
      expect(find.text('Peça 2'), findsOneWidget);
      expect(find.text('Peça 1'), findsNothing);

      await tester.enterText(field('Buscar peça'), '');
      await tester.tap(find.text('Ocultas'));
      await tester.pumpAndSettle();
      expect(find.text('Peça 2'), findsOneWidget);
      expect(find.text('Peça 1'), findsNothing);
    });

    testWidgets('ocultar peça e voltar atrás se o servidor recusar', (
      tester,
    ) async {
      final repo = await open(tester, AppRoutes.adminProducts);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repo.activeChanges, [(id: 'p1', active: false)]);
      expect(find.text('Oculta da loja'), findsOneWidget);

      repo.setActiveFailure = const ServerFailure('Sem conexão.');
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(find.text('Sem conexão.'), findsOneWidget);
      expect(find.text('Oculta da loja'), findsOneWidget, reason: 'desfez');
    });

    testWidgets('lista vazia convida a cadastrar', (tester) async {
      await open(
        tester,
        AppRoutes.adminProducts,
        repo: FakeAdminProductRepository(products: []),
      );

      expect(find.text('Nenhuma peça ainda'), findsOneWidget);
      await tapText(tester, 'Nova peça');
      expect(Get.currentRoute, AppRoutes.adminProductNew);
    });

    testWidgets('tocar na peça abre a edição', (tester) async {
      await open(tester, AppRoutes.adminProducts);

      await tester.tap(find.text('Peça 1'));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, '/admin/produtos/p1');
      expect(find.byType(ProductFormView), findsOneWidget);
    });
  });

  group('formulário', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: edição sem overflow', (tester) async {
        await open(tester, AppRoutes.adminProductEditPath('p1'), size: size);

        expect(find.text('Editar peça'), findsOneWidget);
        expect(find.text('Vestido Midi'), findsOneWidget);
        expect(find.text('Capa'), findsOneWidget);
        expect(find.text('Total em estoque: 4 peças'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('peça inexistente mostra erro', (tester) async {
      await open(tester, AppRoutes.adminProductEditPath('nao-existe'));

      expect(find.text('Peça não encontrada.'), findsOneWidget);
    });

    testWidgets('salvar vazio mostra os erros nos campos', (tester) async {
      final repo = await open(tester, AppRoutes.adminProductNew);

      await tapText(tester, 'Salvar peça');

      expect(find.text('Informe o nome da peça.'), findsOneWidget);
      expect(find.textContaining('Informe um preço válido'), findsOneWidget);
      expect(
        find.text('Adicione ao menos uma cor e um tamanho.'),
        findsOneWidget,
      );
      expect(repo.saved, isEmpty);
    });

    testWidgets('cadastra peça nova: foto, cor, tamanhos e estoque', (
      tester,
    ) async {
      final repo = await open(
        tester,
        AppRoutes.adminProductNew,
        size: const Size(390, 844),
      );

      await tester.enterText(field('Nome da peça'), 'Saia Plissada');
      await tester.enterText(field('Preço'), '159,90');
      await tester.enterText(field('Preço "de" (opcional)'), '199,90');

      await tapText(tester, 'Adicionar\nfotos');
      expect(find.byType(Image), findsWidgets);

      await tapText(tester, 'Adicionar cor');
      await tester.tap(find.bySemanticsLabel('Amostra Rosa'));
      await tester.pump();
      await tester.tap(find.text('Salvar cor'));
      await tester.pumpAndSettle();
      expect(find.text('Rosa'), findsWidgets);

      await tapText(tester, '+ P');
      await tapText(tester, '+ M');

      final stockP = find.byKey(const ValueKey('n0|P'));
      await tester.ensureVisible(stockP);
      await tester.enterText(stockP, '3');
      await tester.enterText(find.byKey(const ValueKey('n0|M')), '0');
      await tester.pump();
      expect(find.text('Total em estoque: 3 peças'), findsOneWidget);

      await tapText(tester, 'Salvar peça');

      final saved = repo.saved.single;
      expect(saved.name, 'Saia Plissada');
      expect(saved.price, 159.9);
      expect(saved.compareAtPrice, 199.9);
      expect(saved.images.single.storagePath, '${saved.id}/foto-0.webp');
      expect(saved.variants.map((v) => '${v.size}:${v.stock}'), [
        'P:3',
        'M:0',
      ]);
      expect(saved.variants.first.colorHex, '#F4A7B9');
      expect(Get.currentRoute, AppRoutes.adminProducts);
      expect(find.text('“Saia Plissada” salva.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('edição: estoque, capa e foto removida', (tester) async {
      final repo = await open(tester, AppRoutes.adminProductEditPath('p1'));

      await tester.enterText(find.byKey(const ValueKey('c0|M')), '5');
      await tester.tap(find.byTooltip('Usar como capa').last);
      await tester.pump();
      await tester.tap(find.byTooltip('Remover foto').last);
      await tester.pump();

      await tapText(tester, 'Salvar peça');

      final saved = repo.saved.single;
      final m = saved.variants.firstWhere((v) => v.size == 'M');
      expect((m.id, m.stock, m.baseStock), ('v2', 5, 1));
      expect(saved.images.single.storagePath, 'p1/costas.webp');
      expect(repo.removed, [
        ['p1/capa.webp'],
      ]);
    });

    testWidgets('remover cor e tamanho tira as combinações', (tester) async {
      final repo = await open(tester, AppRoutes.adminProductEditPath('p1'));

      await tester.tap(find.byTooltip('Remover tamanho M'));
      await tester.pump();
      expect(find.text('Total em estoque: 3 peças'), findsOneWidget);

      await tester.tap(find.text('Rosa').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remover cor'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Salvar peça');

      expect(repo.saved, isEmpty);
      expect(
        find.text('Adicione ao menos uma cor e um tamanho.'),
        findsOneWidget,
      );
    });

    testWidgets('tamanho e cor repetidos são recusados', (tester) async {
      await open(tester, AppRoutes.adminProductEditPath('p1'));

      await tester.enterText(field('Outro tamanho'), 'p');
      await tapText(tester, 'Adicionar');
      expect(find.text('Esse tamanho já está na peça.'), findsOneWidget);

      await tapText(tester, 'Adicionar cor');
      await tester.enterText(field('Nome da cor'), 'rosa');
      await tester.tap(find.text('Salvar cor'));
      await tester.pumpAndSettle();
      expect(find.text('Essa cor já está na peça.'), findsOneWidget);
    });

    testWidgets('categoria nova já fica selecionada', (tester) async {
      final repo = await open(tester, AppRoutes.adminProductNew);

      await tester.tap(find.byTooltip('Nova categoria'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Nome'), 'Saias');
      await tester.tap(find.text('Criar'));
      await tester.pumpAndSettle();

      expect(repo.categories.last.name, 'Saias');
      expect(find.text('Saias'), findsOneWidget);
    });

    testWidgets('erro do servidor aparece e a peça não sai da tela', (
      tester,
    ) async {
      final repo = FakeAdminProductRepository()
        ..saveFailure = const ServerFailure(
          'Tem cor e tamanho repetidos na grade.',
        );
      await open(tester, AppRoutes.adminProductEditPath('p1'), repo: repo);

      await tapText(tester, 'Salvar peça');

      expect(
        find.text('Tem cor e tamanho repetidos na grade.'),
        findsOneWidget,
      );
      expect(Get.currentRoute, '/admin/produtos/p1');
    });
  });
}
