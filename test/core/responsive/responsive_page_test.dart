import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(Get.reset);

  const probe = Key('probe');
  const body = SizedBox(key: probe, width: double.infinity, height: 40);

  group('ResponsivePage', () {
    final expectedWidths = <String, double>{
      'mobile 390': 390 - 2 * 16,
      'tablet 820': 820 - 2 * 24,
      // Largura máxima 1280 menos o padding de desktop.
      'desktop 1440': AppResponsive.maxContentWidth - 2 * 32,
    };

    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: aplica padding e largura máxima', (tester) async {
        await tester.pumpApp(const ResponsivePage(body: body), size: size);

        expect(tester.getSize(find.byKey(probe)).width, expectedWidths[name]);
      });
    }

    testWidgets('desktop centraliza o conteúdo', (tester) async {
      await tester.pumpApp(
        const ResponsivePage(body: body),
        size: const Size(1440, 900),
      );

      final rect = tester.getRect(find.byKey(probe));
      expect(rect.center.dx, closeTo(720, 0.5));
    });

    testWidgets('scrollable: false não envolve em SingleChildScrollView', (
      tester,
    ) async {
      await tester.pumpApp(const ResponsivePage(scrollable: false, body: body));

      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('padding customizado sobrescreve o do dispositivo', (
      tester,
    ) async {
      await tester.pumpApp(
        const ResponsivePage(padding: EdgeInsets.zero, body: body),
      );

      expect(tester.getSize(find.byKey(probe)).width, 390);
    });
  });

  group('ResponsiveBuilder', () {
    for (final MapEntry(key: name, value: size) in testViewports.entries) {
      testWidgets('$name: escolhe o builder certo', (tester) async {
        await tester.pumpApp(
          ResponsiveBuilder(
            mobile: (_) => const Text('mobile'),
            tablet: (_) => const Text('tablet'),
            desktop: (_) => const Text('desktop'),
          ),
          size: size,
        );

        expect(find.text(name.split(' ').first), findsOneWidget);
      });
    }
  });
}
