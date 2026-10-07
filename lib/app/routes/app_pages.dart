import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/middlewares/admin_guard.dart';
import 'package:joyjoy/app/middlewares/strict_route_middleware.dart';
import 'package:joyjoy/app/pages/design_system_view.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/deferred_view.dart';
import 'package:joyjoy/core/pages/not_found_view.dart';
import 'package:joyjoy/features/admin/admin_area.dart' deferred as admin_area;
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/login_controller.dart';
import 'package:joyjoy/features/admin/auth/presentation/views/login_view.dart';
import 'package:joyjoy/features/cart/presentation/views/cart_view.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/presentation/bindings/catalog_binding.dart';
import 'package:joyjoy/features/catalog/presentation/bindings/landing_binding.dart';
import 'package:joyjoy/features/catalog/presentation/bindings/product_detail_binding.dart';
import 'package:joyjoy/features/catalog/presentation/views/catalog_view.dart';
import 'package:joyjoy/features/catalog/presentation/views/landing_view.dart';
import 'package:joyjoy/features/catalog/presentation/views/product_detail_view.dart';
import 'package:joyjoy/features/order/presentation/bindings/order_bindings.dart';
import 'package:joyjoy/features/order/presentation/views/checkout_view.dart';
import 'package:joyjoy/features/order/presentation/views/order_view.dart';

/// Tabela de rotas do GetX. Cada feature registra aqui sua página com [_page].
abstract final class AppPages {
  static final notFound = GetPage<void>(
    name: AppRoutes.notFound,
    page: NotFoundView.new,
  );

  static final pages = <GetPage<dynamic>>[
    _page<void>(
      name: AppRoutes.landing,
      page: LandingView.new,
      binding: LandingBinding(),
    ),
    _page<void>(
      name: AppRoutes.feminino,
      page: () => const CatalogView(gender: Gender.feminino),
      binding: CatalogBinding(Gender.feminino),
    ),
    _page<void>(
      name: AppRoutes.masculino,
      page: () => const CatalogView(gender: Gender.masculino),
      binding: CatalogBinding(Gender.masculino),
    ),
    _page<void>(
      name: AppRoutes.product,
      page: () => ProductDetailView(slug: Get.parameters['slug'] ?? ''),
      binding: ProductDetailBinding(),
    ),
    _page<void>(name: AppRoutes.cart, page: CartView.new),
    _page<void>(
      name: AppRoutes.checkout,
      page: CheckoutView.new,
      binding: CheckoutBinding(),
    ),
    _page<void>(
      name: AppRoutes.order,
      page: () => OrderView(code: (Get.parameters['code'] ?? '').toUpperCase()),
      binding: OrderBinding(),
    ),
    // Admin (ADR-0011). Login no bundle principal; o resto é deferred.
    _page<void>(
      name: AppRoutes.adminLogin,
      page: LoginView.new,
      binding: BindingsBuilder<void>(
        () => Get.lazyPut(
          () => LoginController(
            auth: Get.find<AuthController>(),
            next: Get.parameters['next'],
          ),
        ),
      ),
    ),
    _page<void>(
      name: AppRoutes.admin,
      page: () => DeferredView(
        load: admin_area.loadLibrary,
        builder: (_) => admin_area.buildAdminHome(),
      ),
      middlewares: [AdminGuard()],
    ),
    _page<void>(
      name: AppRoutes.adminOrders,
      page: () => DeferredView(
        load: admin_area.loadLibrary,
        builder: (_) => admin_area.buildAdminOrders(),
      ),
      middlewares: [AdminGuard()],
    ),
    _page<void>(
      name: AppRoutes.adminProducts,
      page: () => DeferredView(
        load: admin_area.loadLibrary,
        builder: (_) => admin_area.buildAdminProducts(),
      ),
      middlewares: [AdminGuard()],
    ),
    // `nova` antes de `:id`: o GetX usa a primeira rota que casar.
    _page<void>(
      name: AppRoutes.adminProductNew,
      page: () => DeferredView(
        load: admin_area.loadLibrary,
        builder: (_) => admin_area.buildAdminProductForm(null),
      ),
      middlewares: [AdminGuard()],
    ),
    _page<void>(
      name: AppRoutes.adminProductEdit,
      page: () {
        final id = Get.parameters['id'] ?? '';
        return DeferredView(
          load: admin_area.loadLibrary,
          builder: (_) => admin_area.buildAdminProductForm(id),
        );
      },
      middlewares: [AdminGuard()],
    ),
    if (kDebugMode)
      _page<void>(name: AppRoutes.designSystem, page: DesignSystemView.new),
    notFound,
  ];

  /// Toda página passa por aqui para receber o [StrictRouteMiddleware].
  static GetPage<T> _page<T>({
    required String name,
    required GetPageBuilder page,
    Bindings? binding,
    List<GetMiddleware> middlewares = const [],
  }) => GetPage<T>(
    name: name,
    page: page,
    binding: binding,
    middlewares: [StrictRouteMiddleware(name), ...middlewares],
  );
}
