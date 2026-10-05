import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/domain/entities/stock_status.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('StockStatus.from', () {
    test(
      '0 = esgotado, até o limite = últimas unidades, acima = disponível',
      () {
        StockStatus s(int total) =>
            StockStatus.from(totalStock: total, lowThreshold: 2);

        expect(s(0), StockStatus.soldOut);
        expect(s(-1), StockStatus.soldOut);
        expect(s(1), StockStatus.low);
        expect(s(2), StockStatus.low);
        expect(s(3), StockStatus.available);
      },
    );
  });

  group('Product', () {
    test('desconto só quando o preço "de" é maior', () {
      expect(
        fakeProduct(1, price: 25, compareAtPrice: 49.99).hasDiscount,
        isTrue,
      );
      expect(
        fakeProduct(1, price: 50, compareAtPrice: 50).hasDiscount,
        isFalse,
      );
      expect(fakeProduct(1).hasDiscount, isFalse);
    });

    test('percentual de desconto arredondado', () {
      expect(
        fakeProduct(1, price: 98, compareAtPrice: 129.90).discountPercent,
        25,
      );
      expect(fakeProduct(1).discountPercent, 0);
    });

    test('status de estoque usa o limite da loja', () {
      final product = fakeProduct(1, stock: 3);

      expect(product.stockStatus(2), StockStatus.available);
      expect(product.stockStatus(5), StockStatus.low);
    });
  });

  test('Gender.fromName com valor desconhecido cai em unissex', () {
    expect(Gender.fromName('feminino'), Gender.feminino);
    expect(Gender.fromName('???'), Gender.unissex);
  });

  test('ProductQuery.nextPage avança o offset mantendo os filtros', () {
    const query = ProductQuery(
      gender: Gender.masculino,
      categoryId: 'c1',
      limit: 10,
    );
    final next = query.nextPage();

    expect(next.offset, 10);
    expect(next.gender, Gender.masculino);
    expect(next.categoryId, 'c1');
  });
}
