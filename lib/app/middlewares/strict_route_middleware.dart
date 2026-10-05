import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/routes/route_pattern.dart';

/// Redireciona para o 404 quando a URL não corresponde exatamente à rota.
///
/// Aplicado a todas as páginas por `AppPages`. Roda antes dos demais
/// middlewares (ex.: `AdminGuard`), por isso a prioridade negativa.
class StrictRouteMiddleware extends GetMiddleware {
  StrictRouteMiddleware(String pattern)
    : _pattern = RoutePattern(pattern),
      super(priority: -100);

  final RoutePattern _pattern;

  @override
  RouteSettings? redirect(String? route) {
    if (route == null || _pattern.matches(route)) return null;
    return const RouteSettings(name: AppRoutes.notFound);
  }
}
