import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/utils/color_hex.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('SizeOrder', () {
    test('letras em ordem natural, depois números, depois o resto', () {
      final sizes = ['GG', '42', 'U', 'P', '38', 'M', 'PP', 'G', 'XG']
        ..sort(SizeOrder.compare);

      expect(sizes, ['PP', 'P', 'M', 'G', 'GG', 'XG', '38', '42', 'U']);
    });

    test('ignora caixa e espaços', () {
      expect(SizeOrder.compare(' p ', 'M'), lessThan(0));
    });
  });

  group('ProductDetail', () {
    final detail = fakeDetail();

    test('cores na ordem das variantes, sem repetir', () {
      expect(detail.colors.map((c) => c.name), ['Rosa', 'Areia']);
      expect(detail.colors.first.hex, '#F4A7B9');
    });

    test('variantes de uma cor com tamanhos ordenados', () {
      expect(detail.variantsOf('Rosa').map((v) => v.size), ['P', 'M', 'G']);
    });

    test('variante por cor + tamanho', () {
      expect(detail.variantFor(colorName: 'Areia', size: 'M')?.id, 'v4');
      expect(detail.variantFor(colorName: 'Areia', size: 'P'), isNull);
    });

    test('estoque total', () => expect(detail.totalStock, 8));
  });

  test('colorFromHex aceita #RRGGBB e rejeita o resto', () {
    expect(colorFromHex('#F4A7B9')?.toARGB32(), 0xFFF4A7B9);
    expect(colorFromHex('d8c3a5')?.toARGB32(), 0xFFD8C3A5);
    expect(colorFromHex('#FFF'), isNull);
    expect(colorFromHex('vermelho'), isNull);
    expect(colorFromHex(null), isNull);
  });
}
