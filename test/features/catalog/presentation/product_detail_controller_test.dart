import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/domain/usecases/cart_usecases.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

import '../../../helpers/fakes.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeProductRepository repo;
  late FakeLinkLauncher launcher;
  late CartController cart;

  setUp(() {
    Get.testMode = true;
    repo = FakeProductRepository()..details['vestido-midi'] = fakeDetail();
    launcher = FakeLinkLauncher();
    final cartRepo = CartRepositoryImpl(
      CartLocalDataSourceImpl(InMemoryKeyValueStore()),
    );
    cart = CartController(
      loadCart: LoadCart(cartRepo),
      saveCart: SaveCart(cartRepo),
    )..onInit();
  });
  tearDown(Get.reset);

  Future<ProductDetailController> create({
    String slug = 'vestido-midi',
    FakeStoreRepository? store,
  }) async {
    final storeController = Get.put(
      StoreController(
        getStoreSettings: GetStoreSettings(store ?? FakeStoreRepository()),
      ),
    );
    final controller = Get.put(
      ProductDetailController(
        slug: slug,
        getProductBySlug: GetProductBySlug(repo),
        store: storeController,
        launcher: launcher,
        cart: cart,
      ),
      tag: slug,
    );
    await settle();
    return controller;
  }

  test(
    'seleciona a primeira cor com estoque e o primeiro tamanho disponível',
    () async {
      final c = await create();

      expect(c.selectedColor.value, 'Rosa');
      expect(c.selectedSize.value, 'P');
      expect(c.canAddToCart, isTrue);
      expect(c.maxQuantity, 3);
    },
  );

  test('cor sem nenhum estoque não é a padrão', () async {
    repo.details['vestido-midi'] = fakeDetail(
      variants: const [
        ProductVariant(
          id: 'a',
          size: 'M',
          colorName: 'Preto',
          stock: 0,
          price: 10,
        ),
        ProductVariant(
          id: 'b',
          size: 'M',
          colorName: 'Branco',
          stock: 2,
          price: 10,
        ),
      ],
    );
    final c = await create();

    expect(c.selectedColor.value, 'Branco');
  });

  test('quantidade limitada ao estoque e ao teto por item', () async {
    final c = await create();

    c
      ..increment()
      ..increment()
      ..increment()
      ..increment();
    expect(c.quantity.value, 3);

    c
      ..decrement()
      ..decrement()
      ..decrement();
    expect(c.quantity.value, 1);

    repo.details['muito-estoque'] = fakeDetail(
      slug: 'muito-estoque',
      variants: const [
        ProductVariant(
          id: 'x',
          size: 'U',
          colorName: 'Azul',
          stock: 50,
          price: 10,
        ),
      ],
    );
    final big = await create(slug: 'muito-estoque');
    expect(big.maxQuantity, ProductDetailController.maxPerItem);
  });

  test('trocar para tamanho com menos estoque reduz a quantidade', () async {
    final c = await create();
    c
      ..increment()
      ..increment() // 3 do P
      ..selectSize('M'); // M tem 1

    expect(c.quantity.value, 1);
  });

  test(
    'trocar de cor mantém o tamanho se existir com estoque, senão escolhe outro',
    () async {
      final c = await create()
        ..selectSize('M')
        ..selectColor('Areia');
      expect(c.selectedSize.value, 'M');
      expect(c.price, 199.9); // preço da variante

      c
        ..selectColor('Rosa')
        ..selectSize('P')
        ..selectColor('Areia');
      expect(c.selectedSize.value, 'M'); // Areia não tem P
    },
  );

  test('combinação esgotada: não adiciona e oferece Avise-me', () async {
    final c = await create();

    c.selectSize('G');

    expect(c.isSelectionSoldOut, isTrue);
    expect(c.canAddToCart, isFalse);
    expect(
      c.notifyMeMessage(),
      'Olá! Pode me avisar quando chegar? Vestido Midi — Tam: G — Cor: Rosa',
    );
  });

  test('Avise-me abre o WhatsApp da Ana com a mensagem codificada', () async {
    final c = await create();
    c.selectSize('G');

    final opened = await c.notifyMe();

    expect(opened, isTrue);
    final uri = launcher.opened.single;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/5581986323686');
    expect(uri.queryParameters['text'], contains('Tam: G'));
  });

  test('Avise-me sem configuração da loja não abre nada', () async {
    final c = await create(store: FakeStoreRepository(null));
    c.selectSize('G');

    expect(await c.notifyMe(), isFalse);
    expect(launcher.opened, isEmpty);
  });

  test('produto todo esgotado', () async {
    repo.details['vestido-midi'] = fakeDetail(
      variants: const [
        ProductVariant(
          id: 'a',
          size: 'M',
          colorName: 'Preto',
          stock: 0,
          price: 10,
        ),
      ],
    );
    final c = await create();

    expect(c.isProductSoldOut, isTrue);
    expect(c.selectedSize.value, isNull);
    expect(c.canAddToCart, isFalse);
  });

  test(
    'adicionar ao carrinho leva a variante, o preço e a quantidade',
    () async {
      final c = await create();
      c.increment(); // 2 do P

      final outcome = await c.addToCart();

      expect(outcome, AddToCartOutcome.added);
      final item = cart.cart.value.items.single;
      expect(item.variantId, 'v2');
      expect(item.quantity, 2);
      expect(item.size, 'P');
      expect(item.colorName, 'Rosa');
      expect(item.maxQuantity, 3);
      expect(c.quantity.value, 1); // volta para 1 depois de adicionar
    },
  );

  test('não adiciona combinação esgotada', () async {
    final c = await create()
      ..selectSize('G');

    expect(await c.addToCart(), AddToCartOutcome.unavailable);
    expect(cart.cart.value.isEmpty, isTrue);
  });

  test('slug inexistente vira UiFailure(NotFoundFailure)', () async {
    final c = await create(slug: 'nao-existe');

    final state = c.state.value as UiFailure<ProductDetail>;
    expect(state.failure, isA<NotFoundFailure>());
  });
}
