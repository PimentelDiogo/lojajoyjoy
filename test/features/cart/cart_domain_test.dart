import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';

import '../../helpers/fakes.dart';

void main() {
  group('Cart.add', () {
    test('peça nova entra no carrinho', () {
      final (cart, outcome) = Cart.empty.add(fakeCartItem('v1', quantity: 2));

      expect(outcome, AddToCartOutcome.added);
      expect(cart.totalQuantity, 2);
      expect(cart.subtotal, 200);
    });

    test('mesma variante soma a quantidade', () {
      final (first, _) = Cart.empty.add(fakeCartItem('v1'));
      final (cart, outcome) = first.add(fakeCartItem('v1', quantity: 2));

      expect(outcome, AddToCartOutcome.merged);
      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 3);
    });

    test('soma só até o estoque', () {
      final (first, _) = Cart.empty.add(
        fakeCartItem('v1', quantity: 4),
      );
      final (cart, outcome) = first.add(
        fakeCartItem('v1', quantity: 3),
      );

      expect(outcome, AddToCartOutcome.limited);
      expect(cart.items.single.quantity, 5);
    });

    test('já no limite: nada muda', () {
      final (first, _) = Cart.empty.add(
        fakeCartItem('v1', quantity: 5),
      );
      final (cart, outcome) = first.add(fakeCartItem('v1'));

      expect(outcome, AddToCartOutcome.atLimit);
      expect(cart, first);
    });

    test('teto de 10 por item mesmo com muito estoque', () {
      final (cart, outcome) = Cart.empty.add(
        fakeCartItem('v1', quantity: 30, max: 50),
      );

      expect(outcome, AddToCartOutcome.limited);
      expect(cart.items.single.quantity, Cart.maxPerItem);
      expect(cart.items.single.maxQuantity, Cart.maxPerItem);
    });

    test('sem estoque ou quantidade zero: indisponível', () {
      expect(
        Cart.empty.add(fakeCartItem('v1', max: 0)).$2,
        AddToCartOutcome.unavailable,
      );
      expect(
        Cart.empty.add(fakeCartItem('v1', quantity: 0)).$2,
        AddToCartOutcome.unavailable,
      );
    });

    test('limite de peças diferentes', () {
      var cart = Cart.empty;
      for (var i = 0; i < Cart.maxDistinctItems; i++) {
        cart = cart.add(fakeCartItem('v$i')).$1;
      }

      expect(cart.add(fakeCartItem('extra')).$2, AddToCartOutcome.atLimit);
    });
  });

  group('edição', () {
    final base = Cart.empty
        .add(fakeCartItem('v1', quantity: 2, max: 3))
        .$1
        .add(fakeCartItem('v2'))
        .$1;

    test('quantidade fica entre 1 e o limite', () {
      expect(base.updateQuantity('v1', 9).itemFor('v1')!.quantity, 3);
      expect(base.updateQuantity('v1', 0).itemFor('v1')!.quantity, 1);
      expect(base.updateQuantity('nao-existe', 2), base);
    });

    test('observação: apara espaços, corta em 140 e vazia vira null', () {
      expect(
        base.updateNote('v1', '  barra 2 cm  ').itemFor('v1')!.note,
        'barra 2 cm',
      );
      expect(base.updateNote('v1', '   ').itemFor('v1')!.note, isNull);
      final long = 'x' * 200;
      expect(
        base.updateNote('v1', long).itemFor('v1')!.note,
        hasLength(Cart.maxNoteLength),
      );
    });

    test('remover e desfazer na mesma posição', () {
      final removed = base.remove('v1');
      expect(removed.items.map((i) => i.variantId), ['v2']);

      final restored = removed.insertAt(0, base.itemFor('v1')!);
      expect(restored.items.map((i) => i.variantId), ['v1', 'v2']);
      expect(
        restored.insertAt(0, base.itemFor('v1')!),
        restored,
      ); // não duplica
    });
  });
}
