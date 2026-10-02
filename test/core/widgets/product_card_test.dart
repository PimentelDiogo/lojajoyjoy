import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/widgets/product_card.dart';
import 'package:joyjoy/core/widgets/stock_badge.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  Widget card({
    num price = 189.9,
    num? compareAt,
    int discount = 0,
    StockBadgeKind badge = StockBadgeKind.none,
    VoidCallback? onTap,
  }) => SizedBox(
    width: 173,
    height: ProductCard.extentFor(173),
    child: ProductCard(
      name: 'Vestido Midi Linho com um nome bem comprido para quebrar',
      price: price,
      compareAtPrice: compareAt,
      discountPercent: discount,
      stockBadge: badge,
      onTap: onTap ?? () {},
    ),
  );

  testWidgets('sem foto mostra placeholder e não estoura em 173px', (
    tester,
  ) async {
    await tester.pumpApp(card());

    expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    expect(find.text('Comprar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('com desconto mostra preço riscado e selo -%', (tester) async {
    await tester.pumpApp(card(price: 98, compareAt: 129.9, discount: 25));

    expect(find.text('-25%'), findsOneWidget);
    expect(find.text(brl('129,90')), findsOneWidget);
  });

  testWidgets('últimas unidades', (tester) async {
    await tester.pumpApp(card(badge: StockBadgeKind.lowStock));

    expect(find.text('Últimas unidades'), findsOneWidget);
  });

  testWidgets('esgotado: selo, sem % e botão "Ver peça"', (tester) async {
    await tester.pumpApp(
      card(badge: StockBadgeKind.soldOut, compareAt: 200, discount: 5),
    );

    expect(find.text('Esgotado'), findsOneWidget);
    expect(find.text('-5%'), findsNothing);
    expect(find.text('Ver peça'), findsOneWidget);
  });

  testWidgets('tocar no card ou no botão chama onTap', (tester) async {
    var taps = 0;
    await tester.pumpApp(card(onTap: () => taps++));

    await tester.tap(find.text('Comprar'));
    await tester.tap(find.byIcon(Icons.checkroom_outlined));

    expect(taps, 2);
  });
}
