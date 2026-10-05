import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/middlewares/strict_route_middleware.dart';
import 'package:joyjoy/app/pages/design_system_view.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/pages/not_found_view.dart';
import 'package:joyjoy/features/cart/presentation/views/cart_view.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/presentation/bindings/catalog_binding.dart';
import 'package:joyjoy/features/catalog/presentation/bindings/landing_binding.dart';
import 'package:joyjoy/features/catalog/presentation/bindings/product_detail_binding.dart';
import 'package:joyjoy/features/catalog/presentation/views/catalog_view.dart';
import 'package:joyjoy/features/catalog/presentation/views/landing_view.dart';
import 'package:joyjoy/features/catalog/presentation/views/product_detail_view.dart';

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
