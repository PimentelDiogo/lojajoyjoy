import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ondas_que_faltam/app/middlewares/strict_route_middleware.dart';
import 'package:ondas_que_faltam/app/pages/design_system_view.dart';
import 'package:ondas_que_faltam/app/routes/app_routes.dart';
import 'package:ondas_que_faltam/core/pages/not_found_view.dart';
import 'package:ondas_que_faltam/features/landing/presentation/views/landing_view.dart';

/// Tabela de rotas do GetX. Cada feature registra aqui sua página com [_page].
abstract final class AppPages {
  static final notFound = GetPage<void>(
    name: AppRoutes.notFound,
    page: NotFoundView.new,
  );

  static final pages = <GetPage<dynamic>>[
    _page<void>(name: AppRoutes.landing, page: LandingView.new),
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
