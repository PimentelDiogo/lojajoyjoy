import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';

void main() {
  group('WhatsAppLink.build', () {
    test('sem mensagem gera só o número', () {
      expect(
        WhatsAppLink.build('5581986323686').toString(),
        'https://wa.me/5581986323686',
      );
    });

    test('codifica acentos, emoji, espaços e quebras de linha', () {
      final uri = WhatsAppLink.build(
        '5581986323686',
        message: 'Olá! 👋\nTam: M',
      );

      expect(uri.host, 'wa.me');
      expect(uri.path, '/5581986323686');
      expect(uri.queryParameters['text'], 'Olá! 👋\nTam: M');
      expect(uri.toString(), contains('%20'));
      expect(uri.toString(), isNot(contains(' ')));
    });

    test('texto malicioso não injeta parâmetros nem troca o destino', () {
      final uri = WhatsAppLink.build(
        '5581986323686',
        message: 'oi&phone=5511999999999#@evil.com/?x=1',
      );

      expect(uri.host, 'wa.me');
      expect(uri.path, '/5581986323686');
      expect(uri.queryParameters.keys, ['text']);
      expect(uri.fragment, isEmpty);
      expect(
        uri.queryParameters['text'],
        'oi&phone=5511999999999#@evil.com/?x=1',
      );
    });

    test('mensagem vazia ou só espaços é ignorada', () {
      expect(
        WhatsAppLink.build('5581986323686', message: '   ').query,
        isEmpty,
      );
    });

    test('tryBuild devolve null em vez de lançar', () {
      expect(WhatsAppLink.tryBuild('81 98632-3686'), isNull);
      expect(WhatsAppLink.tryBuild('5581986323686')?.host, 'wa.me');
    });

    test('número fora do formato wa.me é rejeitado', () {
      for (final invalid in ['81986323686', '+55 81 98632-3686', 'abc', '']) {
        expect(
          () => WhatsAppLink.build(invalid),
          throwsArgumentError,
          reason: invalid,
        );
      }
    });
  });
}
