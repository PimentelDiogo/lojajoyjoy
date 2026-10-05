import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/domain/usecases/cart_usecases.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';

import '../../helpers/fakes.dart';

void main() {
  late InMemoryKeyValueStore kv;
  late CartRepositoryImpl repo;

  setUp(() {
    kv = InMemoryKeyValueStore();
    repo = CartRepositoryImpl(CartLocalDataSourceImpl(kv));
  });

  group('CartRepositoryImpl', () {
    test('salva e carrega o mesmo carrinho (inclui observação)', () async {
      final cart = Cart.empty
          .add(fakeCartItem('v1', quantity: 2, note: 'barra'))
          .$1;

      await repo.save(cart);

      expect(repo.load(), cart);
      expect(
        kv.read(CartLocalDataSourceImpl.storageKey),
        contains('"note":"barra"'),
      );
    });

    test('nada salvo = vazio', () => expect(repo.load(), Cart.empty));

    test('JSON corrompido = vazio (não quebra a loja)', () async {
      await kv.write(CartLocalDataSourceImpl.storageKey, '{isso não é json');
      expect(repo.load(), Cart.empty);

      await kv.write(
        CartLocalDataSourceImpl.storageKey,
        jsonEncode([
          {'x': 1},
        ]),
      );
      expect(repo.load(), Cart.empty);
    });

    test(
      'dados adulterados passam pelas regras do domain ao carregar',
      () async {
        await kv.write(
          CartLocalDataSourceImpl.storageKey,
          jsonEncode([
            {
              'variant_id': 'v1',
              'slug': 's',
              'name': 'n',
              'size': 'M',
              'color': 'Rosa',
              'price': 10,
              'qty': 999,
              'max': 999,
              'note': ' ${'y' * 300} ',
            },
          ]),
        );

        final item = repo.load().items.single;
        expect(item.quantity, Cart.maxPerItem);
        expect(item.note, hasLength(Cart.maxNoteLength));
      },
    );
  });

  group('CartController', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    CartController create() => Get.put(
      CartController(loadCart: LoadCart(repo), saveCart: SaveCart(repo)),
    );

    test('carrega o carrinho salvo ao iniciar', () async {
      await repo.save(Cart.empty.add(fakeCartItem('v1', quantity: 3)).$1);

      expect(create().totalQuantity, 3);
    });

    test('adicionar, editar e remover persistem', () async {
      final c = create();

      await c.add(fakeCartItem('v1'));
      await c.updateQuantity('v1', 4);
      await c.updateNote('v1', 'sem etiqueta');
      expect(repo.load().items.single.quantity, 4);
      expect(repo.load().items.single.note, 'sem etiqueta');

      final removed = await c.remove('v1');
      expect(repo.load().isEmpty, isTrue);

      await c.undoRemove(removed!.$1, removed.$2);
      expect(repo.load().items.single.variantId, 'v1');

      await c.clear();
      expect(c.cart.value.isEmpty, isTrue);
    });

    test('remover item inexistente devolve null', () async {
      expect(await create().remove('nada'), isNull);
    });
  });
}
