import 'package:get/get.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';
import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/domain/usecases/cart_usecases.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/domain/repositories/store_repository.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

// -----------------------------------------------------------------------------
// Dados de exemplo (mock de teste: evita depender do banco nos testes de UI)
// -----------------------------------------------------------------------------

Product fakeProduct(
  int i, {
  Gender gender = Gender.feminino,
  num price = 100,
  num? compareAtPrice,
  int stock = 10,
  bool featured = false,
}) => Product(
  id: 'p$i',
  name: 'Peça $i',
  slug: 'peca-$i',
  gender: gender,
  price: price,
  compareAtPrice: compareAtPrice,
  totalStock: stock,
  isFeatured: featured,
);

List<Product> fakeProducts(
  int count, {
  int start = 0,
  Gender gender = Gender.feminino,
}) => [
  for (var i = start; i < start + count; i++) fakeProduct(i, gender: gender),
];

/// Vestido com 2 cores: Rosa (P=3, M=1, G=0) e Areia (M=4). Mock de teste.
ProductDetail fakeDetail({
  String slug = 'vestido-midi',
  List<ProductVariant>? variants,
  List<String> images = const [],
  String? description = 'Linho leve.',
}) => ProductDetail(
  id: 'd1',
  name: 'Vestido Midi',
  slug: slug,
  gender: Gender.feminino,
  price: 189.9,
  description: description,
  imageUrls: images,
  variants:
      variants ??
      const [
        ProductVariant(
          id: 'v1',
          size: 'G',
          colorName: 'Rosa',
          colorHex: '#F4A7B9',
          stock: 0,
          price: 189.9,
        ),
        ProductVariant(
          id: 'v2',
          size: 'P',
          colorName: 'Rosa',
          colorHex: '#F4A7B9',
          stock: 3,
          price: 189.9,
        ),
        ProductVariant(
          id: 'v3',
          size: 'M',
          colorName: 'Rosa',
          colorHex: '#F4A7B9',
          stock: 1,
          price: 189.9,
        ),
        ProductVariant(
          id: 'v4',
          size: 'M',
          colorName: 'Areia',
          colorHex: '#D8C3A5',
          stock: 4,
          price: 199.9,
        ),
      ],
);

const fakeCategories = [
  Category(
    id: 'c1',
    name: 'Vestidos',
    slug: 'vestidos',
    gender: Gender.feminino,
  ),
  Category(id: 'c2', name: 'Blusas', slug: 'blusas', gender: Gender.feminino),
];

const fakeSettings = StoreSettings(
  storeName: 'JOYJOY',
  whatsappNumber: '5581986323686',
  greetingMessage: 'Olá!',
  isOpen: true,
  lowStockThreshold: 2,
);

const testEnv = Env(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseAnonKey: 'anon',
  appBaseUrl: 'http://localhost:8080',
);

// -----------------------------------------------------------------------------
// Fakes
// -----------------------------------------------------------------------------

class FakeProductRepository implements ProductRepository {
  FakeProductRepository([List<Product>? catalog])
    : catalog = catalog ?? fakeProducts(5);

  /// Todos os produtos "do banco"; a query aplica offset/limit/featured.
  List<Product> catalog;

  /// Quando definido, todas as chamadas falham com ele.
  Failure? failure;

  final List<ProductQuery> queries = [];

  /// Produtos de detalhe por slug (ausente = NotFoundFailure).
  final Map<String, ProductDetail> details = {};

  @override
  Future<Result<ProductDetail>> getProductBySlug(String slug) async {
    if (failure != null) return Failed(failure!);
    final detail = details[slug];
    return detail == null
        ? const Failed(NotFoundFailure('Essa peça não está mais disponível.'))
        : Success(detail);
  }

  @override
  Future<Result<List<Product>>> getProducts(ProductQuery query) async {
    queries.add(query);
    if (failure != null) return Failed(failure!);
    final source = query.featuredOnly
        ? catalog.where((p) => p.isFeatured).toList()
        : catalog;
    return Success(source.skip(query.offset).take(query.limit).toList());
  }
}

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([this.categories = fakeCategories]);

  final List<Category> categories;

  @override
  Future<Result<List<Category>>> getCategories(Gender gender) async =>
      Success(categories);
}

class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository([this.settings = fakeSettings]);

  StoreSettings? settings;

  @override
  Future<Result<StoreSettings>> getSettings() async =>
      settings == null ? const Failed(NetworkFailure()) : Success(settings!);
}

class FakeLinkLauncher implements LinkLauncher {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Registra as dependências globais com fakes (equivalente ao InitialBinding).
({
  FakeProductRepository products,
  FakeStoreRepository store,
  FakeLinkLauncher launcher,
  InMemoryKeyValueStore storage,
  CartController cart,
})
registerAppFakes({
  FakeProductRepository? products,
  FakeCategoryRepository? categories,
  FakeStoreRepository? store,
  InMemoryKeyValueStore? storage,
}) {
  final productRepo = products ?? FakeProductRepository();
  final storeRepo = store ?? FakeStoreRepository();
  final launcher = FakeLinkLauncher();
  final kv = storage ?? InMemoryKeyValueStore();
  final cartRepo = CartRepositoryImpl(CartLocalDataSourceImpl(kv));
  final cart = CartController(
    loadCart: LoadCart(cartRepo),
    saveCart: SaveCart(cartRepo),
  );

  Get
    ..testMode = true
    ..put<Env>(testEnv, permanent: true)
    ..put<KeyValueStore>(kv, permanent: true)
    ..put<LinkLauncher>(launcher, permanent: true)
    ..put(ThemeController(kv), permanent: true)
    ..put(cart, permanent: true)
    ..put<StoreRepository>(storeRepo, permanent: true)
    ..put(
      StoreController(getStoreSettings: GetStoreSettings(storeRepo)),
      permanent: true,
    )
    ..put<ProductRepository>(productRepo, permanent: true)
    ..put<CategoryRepository>(
      categories ?? FakeCategoryRepository(),
      permanent: true,
    );

  return (
    products: productRepo,
    store: storeRepo,
    launcher: launcher,
    storage: kv,
    cart: cart,
  );
}

/// Item de carrinho de exemplo (mock de teste).
CartItem fakeCartItem(
  String variantId, {
  int quantity = 1,
  int max = 5,
  num price = 100,
  String? note,
}) => CartItem(
  variantId: variantId,
  productSlug: 'peca-$variantId',
  productName: 'Peça $variantId',
  size: 'M',
  colorName: 'Rosa',
  colorHex: '#F4A7B9',
  unitPrice: price,
  quantity: quantity,
  maxQuantity: max,
  note: note,
);
