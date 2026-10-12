import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/browser_info.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:joyjoy/features/admin/orders/domain/admin_orders.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
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
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/order_repository.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/domain/repositories/store_repository.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:joyjoy/features/tracking/domain/tracking_repository.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';
import 'package:joyjoy/features/tracking/presentation/session_tracker.dart';

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
  instagramHandle: 'joyjoybrand_',
  pickupAddress:
      'Rua Professor Júlio Ferreira de Melo, 355 - Boa Viagem, Recife - PE',
  paymentMethods: ['card', 'pix'],
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

/// Pedido como o servidor devolveria (mock de teste).
Order fakeOrder({
  String code = 'K7P2QX',
  OrderStatus status = OrderStatus.pending,
  List<OrderItem>? items,
  num total = 449.7,
  String? customerName,
}) => Order(
  code: code,
  status: status,
  total: total,
  createdAt: DateTime.utc(2026, 10, 5, 15, 30),
  customerName: customerName,
  deliveryMethod: DeliveryMethod.pickup,
  paymentMethod: PaymentMethod.pix,
  items:
      items ??
      const [
        OrderItem(
          productName: 'Vestido Midi Linho',
          size: 'M',
          colorName: 'Rosa',
          unitPrice: 189.9,
          quantity: 1,
        ),
        OrderItem(
          productName: 'Camisa Oxford',
          size: 'G',
          colorName: 'Azul',
          unitPrice: 129.9,
          quantity: 2,
        ),
      ],
);

class FakeOrderRepository implements OrderRepository {
  final List<CheckoutRequest> requests = [];
  final Map<String, Order> orders = {};

  /// Resposta do create_order (padrão: [fakeOrder]).
  Result<Order> createResult = Success(fakeOrder());

  @override
  Future<Result<Order>> createOrder(CheckoutRequest request) async {
    requests.add(request);
    return createResult..fold((order) => orders[order.code] = order, (_) {});
  }

  @override
  Future<Result<Order>> getOrder(String code) async {
    final order = orders[code.toUpperCase()];
    return order == null
        ? const Failed(NotFoundFailure('Pedido não encontrado.'))
        : Success(order);
  }

  /// Ações da Ana (código do pedido), para conferir nos testes.
  final List<String> actions = [];

  /// Se definido, confirmar/cancelar falham com isto.
  Failure? actionFailure;

  @override
  Future<Result<Order>> confirmOrder(String code) =>
      _act('confirm', code, OrderStatus.confirmed);

  @override
  Future<Result<Order>> cancelOrder(String code) =>
      _act('cancel', code, OrderStatus.cancelled);

  Future<Result<Order>> _act(
    String action,
    String code,
    OrderStatus status,
  ) async {
    actions.add('$action:$code');
    if (actionFailure case final failure?) return Failed(failure);
    final current = orders[code];
    if (current == null) {
      return const Failed(NotFoundFailure('Pedido não encontrado.'));
    }
    final updated = fakeOrder(
      code: code,
      status: status,
      items: current.items,
      total: current.total,
      customerName: current.customerName,
    );
    orders[code] = updated;
    return Success(updated);
  }
}

AdminOrderSummary fakeAdminOrder(
  String code, {
  OrderStatus status = OrderStatus.pending,
  String? customerName = 'Maria',
}) => AdminOrderSummary(
  code: code,
  status: status,
  total: 189.9,
  createdAt: DateTime.utc(2026, 10, 5, 15, 30),
  itemCount: 2,
  customerName: customerName,
  source: 'instagram',
);

class FakeAdminOrderRepository implements AdminOrderRepository {
  FakeAdminOrderRepository([List<AdminOrderSummary>? orders])
    : orders =
          orders ??
          [
            fakeAdminOrder('AAA111'),
            fakeAdminOrder('BBB222', status: OrderStatus.confirmed),
            fakeAdminOrder('CCC333', status: OrderStatus.cancelled),
            fakeAdminOrder('DDD444', customerName: null),
          ];

  List<AdminOrderSummary> orders;

  @override
  Future<Result<List<AdminOrderSummary>>> listOrders() async => Success(orders);
}

class FakeTrackingRepository implements TrackingRepository {
  final List<(String, SourceDetection, String, String)> visits = [];

  @override
  Future<Result<void>> trackVisit({
    required String sessionId,
    required SourceDetection detection,
    required String landingPath,
    required String deviceType,
  }) async {
    visits.add((sessionId, detection, landingPath, deviceType));
    return const Success(null);
  }
}

const fakeAdmin = AdminUser(id: 'a1', email: 'ana@joyjoy.com.br');

/// Login fake: senha correta = 'senha-certa'; [isAdmin] decide o acesso.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session = false, this.isAdmin = true});

  bool session;
  bool isAdmin;
  int signOuts = 0;

  @override
  bool get hasSession => session;

  @override
  Future<Result<AdminUser>> signIn(SignInParams params) async {
    if (params.password != 'senha-certa') {
      return const Failed(UnauthorizedFailure('E-mail ou senha incorretos.'));
    }
    session = true;
    return currentAdmin();
  }

  @override
  Future<Result<AdminUser>> currentAdmin() async {
    if (!session) return const Failed(UnauthorizedFailure());
    if (!isAdmin) {
      session = false;
      return const Failed(
        UnauthorizedFailure('Este usuário não tem acesso à área da loja.'),
      );
    }
    return const Success(fakeAdmin);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    session = false;
  }

  final List<(String, Uri)> resetRequests = [];
  final List<String> passwordUpdates = [];

  @override
  Future<Result<void>> requestPasswordReset(
    String email, {
    required Uri redirectTo,
  }) async {
    resetRequests.add((email, redirectTo));
    return const Success(null);
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    if (!session) {
      return const Failed(
        UnauthorizedFailure('Link inválido ou expirado. Peça um novo.'),
      );
    }
    passwordUpdates.add(newPassword);
    return const Success(null);
  }
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository([
    this.stats = const AdminStats(
      pendingOrders: 3,
      activeProducts: 6,
      visitsBySource: {'instagram': 12, 'whatsapp': 5, 'site': 2},
    ),
  ]);

  AdminStats stats;
  DateTime? lastSince;

  @override
  Future<Result<AdminStats>> getStats({required DateTime since}) async {
    lastSince = since;
    return Success(stats);
  }
}

/// Peça salva de exemplo para o admin (mock de teste: sem banco nos testes de UI).
ProductDraft fakeDraft({String id = 'p1'}) => ProductDraft(
  id: id,
  isNew: false,
  slug: 'vestido-midi',
  name: 'Vestido Midi',
  description: 'Linho.',
  gender: Gender.feminino,
  categoryId: 'c1',
  price: 189.9,
  images: const [
    DraftImage(key: 'p1/capa.webp', storagePath: 'p1/capa.webp'),
    DraftImage(key: 'p1/costas.webp', storagePath: 'p1/costas.webp'),
  ],
  colors: const [DraftColor(key: 'c0', name: 'Rosa', hex: '#F4A7B9')],
  sizes: const ['P', 'M'],
  cells: const {
    'c0|P': DraftCell(variantId: 'v1', stock: 3, baseStock: 3),
    'c0|M': DraftCell(variantId: 'v2', stock: 1, baseStock: 1),
  },
);

AdminProductSummary fakeAdminProduct(
  int i, {
  bool active = true,
  int stock = 4,
  String? category,
}) => AdminProductSummary(
  id: 'p$i',
  name: 'Peça $i',
  slug: 'peca-$i',
  gender: Gender.feminino,
  price: 100 + i,
  totalStock: stock,
  isActive: active,
  categoryName: category,
);

/// PNG 1×1 válido (o `Image.memory` da prévia precisa decodificar).
final _tinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0, //
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, //
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

PickedImage fakePickedImage() =>
    PickedImage(bytes: _tinyPng, contentType: 'image/webp');

/// Cadastro de peças em memória. Registra cada chamada para os testes.
class FakeAdminProductRepository implements AdminProductRepository {
  FakeAdminProductRepository({
    List<AdminProductSummary>? products,
    Map<String, ProductDraft>? drafts,
    List<Category>? categories,
  }) : products = products ?? [fakeAdminProduct(1), fakeAdminProduct(2)],
       drafts = drafts ?? {'p1': fakeDraft()},
       categories =
           categories ??
           const [
             Category(
               id: 'c1',
               name: 'Vestidos',
               slug: 'vestidos',
               gender: Gender.feminino,
             ),
             Category(
               id: 'c2',
               name: 'Camisas',
               slug: 'camisas',
               gender: Gender.masculino,
             ),
             Category(
               id: 'c3',
               name: 'Calças',
               slug: 'calcas',
               gender: Gender.unissex,
             ),
           ];

  List<AdminProductSummary> products;
  Map<String, ProductDraft> drafts;
  List<Category> categories;

  final List<String> uploads = [];
  final List<List<String>> removed = [];
  final List<ProductDraft> saved = [];
  final List<({String id, bool active})> activeChanges = [];

  Failure? uploadFailure;
  Failure? saveFailure;
  Failure? setActiveFailure;

  @override
  Future<Result<List<AdminProductSummary>>> listProducts() async =>
      Success(products);

  @override
  Future<Result<ProductDraft>> getDraft(String id) async {
    final draft = drafts[id];
    return draft == null
        ? const Failed(NotFoundFailure('Peça não encontrada.'))
        : Success(draft);
  }

  @override
  Future<Result<void>> setActive(String id, {required bool active}) async {
    activeChanges.add((id: id, active: active));
    if (setActiveFailure case final failure?) return Failed(failure);
    return const Success(null);
  }

  @override
  Future<Result<List<Category>>> listCategories() async => Success(categories);

  @override
  Future<Result<Category>> createCategory(String name, Gender gender) async {
    final category = Category(
      id: 'new-${categories.length}',
      name: name,
      slug: name.toLowerCase(),
      gender: gender,
    );
    categories = [...categories, category];
    return Success(category);
  }

  @override
  Future<Result<String>> uploadImage(
    String productId,
    PickedImage image,
  ) async {
    if (uploadFailure case final failure?) return Failed(failure);
    final path = '$productId/foto-${uploads.length}.${image.extension}';
    uploads.add(path);
    return Success(path);
  }

  @override
  Future<Result<SavedProduct>> save(ProductDraft draft) async {
    saved.add(draft);
    if (saveFailure case final failure?) return Failed(failure);
    return Success(SavedProduct(id: draft.id, slug: draft.slug ?? 'nova-peca'));
  }

  @override
  Future<void> removeImages(List<String> storagePaths) async =>
      removed.add(storagePaths);
}

/// Seletor de fotos fake: devolve [next] na próxima escolha.
class FakeImagePicker implements ProductImagePicker {
  List<PickedImage> next = [fakePickedImage()];
  int skipped = 0;
  int? lastMax;

  @override
  Future<({List<PickedImage> images, int skipped})> pick({
    required int max,
  }) async {
    lastMax = max;
    return (images: next.take(max).toList(), skipped: skipped);
  }
}

/// Registra as dependências globais com fakes (equivalente ao InitialBinding).
({
  FakeProductRepository products,
  FakeStoreRepository store,
  FakeLinkLauncher launcher,
  InMemoryKeyValueStore storage,
  CartController cart,
  FakeOrderRepository orders,
  FakeTrackingRepository tracking,
  FakeAuthRepository auth,
  FakeAdminProductRepository adminProducts,
  FakeImagePicker imagePicker,
})
registerAppFakes({
  FakeProductRepository? products,
  FakeCategoryRepository? categories,
  FakeStoreRepository? store,
  InMemoryKeyValueStore? storage,
  FakeOrderRepository? orders,
  FakeAuthRepository? auth,
  FakeAdminProductRepository? adminProducts,
  FakeAdminOrderRepository? adminOrders,
  Uri? url,
}) {
  final adminProductRepo = adminProducts ?? FakeAdminProductRepository();
  final imagePicker = FakeImagePicker();
  final authRepo = auth ?? FakeAuthRepository();
  final orderRepo = orders ?? FakeOrderRepository();
  final tracking = FakeTrackingRepository();
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
    ..put<OrderRepository>(orderRepo, permanent: true)
    ..put<AuthRepository>(authRepo, permanent: true)
    ..put(
      AuthController(
        repository: authRepo,
        signInUseCase: SignIn(authRepo),
        getCurrentAdmin: GetCurrentAdmin(authRepo),
        signOutUseCase: SignOut(authRepo),
      ),
      permanent: true,
    )
    ..put<DashboardRepository>(FakeDashboardRepository(), permanent: true)
    ..put<AdminProductRepository>(adminProductRepo, permanent: true)
    ..put<AdminOrderRepository>(
      adminOrders ?? FakeAdminOrderRepository(),
      permanent: true,
    )
    ..put<ProductImagePicker>(imagePicker, permanent: true)
    ..put(
      SessionTracker(
        store: kv,
        repository: tracking,
        browserInfo: () => BrowserInfo(
          url: url ?? Uri.parse('http://localhost:8080/?src=instagram'),
          userAgent: '',
          referrer: '',
        ),
        deviceType: () => 'mobile',
      ),
      permanent: true,
    )
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
    orders: orderRepo,
    tracking: tracking,
    auth: authRepo,
    adminProducts: adminProductRepo,
    imagePicker: imagePicker,
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
