import 'package:get/get.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
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
})
registerAppFakes({
  FakeProductRepository? products,
  FakeCategoryRepository? categories,
  FakeStoreRepository? store,
}) {
  final productRepo = products ?? FakeProductRepository();
  final storeRepo = store ?? FakeStoreRepository();
  final launcher = FakeLinkLauncher();
  final storage = InMemoryKeyValueStore();

  Get
    ..testMode = true
    ..put<Env>(testEnv, permanent: true)
    ..put<KeyValueStore>(storage, permanent: true)
    ..put<LinkLauncher>(launcher, permanent: true)
    ..put(ThemeController(storage), permanent: true)
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
    storage: storage,
  );
}
