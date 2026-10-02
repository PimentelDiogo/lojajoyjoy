import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/app_wordmark.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/core/widgets/price_text.dart';
import 'package:joyjoy/core/widgets/theme_toggle.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  group('AppButton', () {
    testWidgets('chama onPressed ao tocar', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'Comprar', onPressed: () => taps++),
      );

      await tester.tap(find.text('Comprar'));

      expect(taps, 1);
    });

    testWidgets('carregando: desabilita e mostra indicador', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AppButton(label: 'Comprar', isLoading: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(FilledButton));

      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
    });

    testWidgets('cada variante usa o botão Material certo', (tester) async {
      await tester.pumpApp(
        Column(
          children: [
            for (final v in AppButtonVariant.values)
              AppButton(label: v.name, variant: v, onPressed: () {}),
          ],
        ),
      );

      expect(find.byType(FilledButton), findsNWidgets(2)); // primary + tonal
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('expand ocupa a largura toda', (tester) async {
      await tester.pumpApp(
        AppButton(label: 'Finalizar', expand: true, onPressed: () {}),
      );

      expect(tester.getSize(find.byType(FilledButton)).width, 390);
    });

    testWidgets('label longo não estoura em 390px', (tester) async {
      await tester.pumpApp(
        AppButton(
          label: 'Finalizar pedido no WhatsApp da Ana agora mesmo por favor',
          icon: Icons.chat,
          onPressed: () {},
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('PriceText', () {
    testWidgets('sem desconto mostra só o preço', (tester) async {
      await tester.pumpApp(const PriceText(price: 189.9));

      expect(find.text(brl('189,90')), findsOneWidget);
      expect(find.bySemanticsLabel(brl('189,90')), findsOneWidget);
    });

    testWidgets('com desconto mostra "de" riscado e semântica "De … por …"', (
      tester,
    ) async {
      await tester.pumpApp(const PriceText(price: 25, compareAtPrice: 49.99));

      final old = tester.widget<Text>(find.text(brl('49,99')));
      expect(old.style?.decoration, TextDecoration.lineThrough);
      expect(
        find.bySemanticsLabel('De ${brl('49,99')} por ${brl('25,00')}'),
        findsOneWidget,
      );
    });

    testWidgets('compareAtPrice menor ou igual ao preço é ignorado', (
      tester,
    ) async {
      await tester.pumpApp(const PriceText(price: 50, compareAtPrice: 50));

      expect(find.text(brl('50,00')), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('EmptyState / ErrorState', () {
    testWidgets('EmptyState mostra ação só com label + callback', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        EmptyState(
          title: 'Carrinho vazio',
          message: 'Escolha suas peças',
          actionLabel: 'Ver peças',
          onAction: () => tapped = true,
        ),
      );

      expect(find.text('Escolha suas peças'), findsOneWidget);
      await tester.tap(find.text('Ver peças'));
      expect(tapped, isTrue);
    });

    testWidgets('EmptyState sem ação não mostra botão', (tester) async {
      await tester.pumpApp(const EmptyState(title: 'Nada aqui'));

      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets(
      'ErrorState.fromFailure usa a mensagem e permite tentar de novo',
      (
        tester,
      ) async {
        var retries = 0;
        await tester.pumpApp(
          ErrorState.fromFailure(
            const NetworkFailure(),
            onRetry: () => retries++,
          ),
        );

        expect(
          find.text('Sem conexão. Verifique sua internet.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Tentar novamente'));
        expect(retries, 1);
      },
    );
  });

  group('LoadingSkeleton', () {
    testWidgets('anima normalmente', (tester) async {
      await tester.pumpApp(const LoadingSkeleton(width: 100));

      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(LoadingSkeleton),
          matching: find.byType(FadeTransition),
        ),
      );
      final before = fade.opacity.value;
      await tester.pump(const Duration(milliseconds: 450));
      expect(fade.opacity.value, isNot(before));
    });

    testWidgets('fica parado com "reduzir animações" ligado', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpApp(const LoadingSkeleton(width: 100));
      await tester.pumpAndSettle(); // não trava: não há animação em loop

      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(LoadingSkeleton),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 1);
    });
  });

  group('ThemeToggle', () {
    for (final (mode, tooltip) in [
      (ThemeMode.system, 'Tema: automático'),
      (ThemeMode.light, 'Tema: claro'),
      (ThemeMode.dark, 'Tema: escuro'),
    ]) {
      testWidgets('${mode.name}: tooltip "$tooltip"', (tester) async {
        var taps = 0;
        await tester.pumpApp(ThemeToggle(mode: mode, onPressed: () => taps++));

        expect(find.byTooltip(tooltip), findsOneWidget);
        await tester.tap(find.byType(IconButton));
        expect(taps, 1);
      });
    }
  });

  group('AppHeader', () {
    testWidgets('mostra o nome da loja como cabeçalho e as ações', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          appBar: AppHeader(actions: [Icon(Icons.shopping_bag_outlined)]),
        ),
      );

      expect(find.bySemanticsLabel('JOYJOY'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });

    testWidgets('sem title mostra o wordmark JOYJOY; com title, o texto', (
      tester,
    ) async {
      await tester.pumpApp(const Scaffold(appBar: AppHeader()));
      expect(find.byType(AppWordmark), findsOneWidget);
      expect(find.text('JOYJOY'), findsOneWidget);

      await tester.pumpApp(
        const Scaffold(appBar: AppHeader(title: 'Carrinho')),
      );
      expect(find.byType(AppWordmark), findsNothing);
      expect(find.text('Carrinho'), findsOneWidget);
    });

    testWidgets('faixa padrão usa o laranja do logo', (tester) async {
      await tester.pumpApp(const Scaffold(appBar: AppHeader()));

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.color == AppColors.light.brand,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('nome longo não estoura o header em 390px', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          appBar: AppHeader(
            title: 'Um nome de loja muito comprido para caber no celular',
            actions: [Icon(Icons.shopping_bag_outlined), Icon(Icons.search)],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('pinta a faixa de destaque da seção', (tester) async {
      await tester.pumpApp(
        const Scaffold(appBar: AppHeader(accentColor: Color(0xFFF9D5DF))),
      );

      final strip = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.color == const Color(0xFFF9D5DF),
          ),
        ),
      );
      expect(strip, isNotNull);
    });
  });
}
