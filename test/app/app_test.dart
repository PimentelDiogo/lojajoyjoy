import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ondas_que_faltam/app/app.dart';
import 'package:ondas_que_faltam/core/config/env.dart';

void main() {
  const env = Env(
    supabaseUrl: '',
    supabaseAnonKey: '',
    appBaseUrl: 'http://localhost:8080',
  );

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('abre na landing e injeta o Env global', (tester) async {
    await tester.pumpWidget(const OndasApp(env: env));
    await tester.pumpAndSettle();

    expect(find.text('Ondas que Faltam'), findsOneWidget);
    expect(Get.find<Env>(), same(env));
  });

  testWidgets(
    'rota desconhecida mostra "Página não encontrada" e volta para a loja',
    (tester) async {
      await tester.pumpWidget(const OndasApp(env: env));
      await tester.pumpAndSettle();

      unawaited(Get.toNamed<void>('/rota-que-nao-existe'));
      await tester.pumpAndSettle();
      expect(find.text('Página não encontrada'), findsOneWidget);

      await tester.tap(find.text('Voltar para a loja'));
      await tester.pumpAndSettle();
      expect(find.text('Vitrine em construção'), findsOneWidget);
    },
  );
}
