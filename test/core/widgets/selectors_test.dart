import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/widgets/option_selectors.dart';
import 'package:joyjoy/core/widgets/quantity_stepper.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('SizeSelector: esgotado riscado mas clicável', (tester) async {
    String? picked;
    await tester.pumpApp(
      SizeSelector(
        options: const [
          SelectorOption(value: 'P'),
          SelectorOption(value: 'G', available: false),
        ],
        selected: 'P',
        onSelected: (v) => picked = v,
      ),
    );

    final g = tester.widget<Text>(find.text('G'));
    expect(g.style?.decoration, TextDecoration.lineThrough);
    expect(find.bySemanticsLabel('Tamanho G, esgotado'), findsOneWidget);

    await tester.tap(find.text('G'));
    expect(picked, 'G');
  });

  testWidgets('SizeSelector: alvo de toque ≥ 48px', (tester) async {
    await tester.pumpApp(
      SizeSelector(
        options: const [SelectorOption(value: 'P')],
        selected: null,
        onSelected: (_) {},
      ),
    );

    final size = tester.getSize(find.byType(InkWell).first);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('ColorSelector: amostra, selecionada e esgotada', (tester) async {
    String? picked;
    await tester.pumpApp(
      ColorSelector(
        options: const [
          SelectorOption(value: 'Rosa', swatch: Color(0xFFF4A7B9)),
          SelectorOption(value: 'Areia', available: false),
        ],
        selected: 'Rosa',
        onSelected: (v) => picked = v,
      ),
    );

    expect(find.bySemanticsLabel('Cor Rosa'), findsOneWidget);
    expect(find.bySemanticsLabel('Cor Areia, esgotada'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // sem hex: inicial do nome

    await tester.tap(find.bySemanticsLabel('Cor Areia, esgotada'));
    expect(picked, 'Areia');
  });

  testWidgets('QuantityStepper respeita min e max', (tester) async {
    var inc = 0;
    var dec = 0;
    await tester.pumpApp(
      QuantityStepper(
        value: 1,
        max: 1,
        onIncrement: () => inc++,
        onDecrement: () => dec++,
      ),
    );

    await tester.tap(find.byTooltip('Aumentar quantidade'));
    await tester.tap(find.byTooltip('Diminuir quantidade'));

    expect(inc, 0);
    expect(dec, 0);
    expect(find.bySemanticsLabel('Quantidade 1'), findsOneWidget);
  });
}
