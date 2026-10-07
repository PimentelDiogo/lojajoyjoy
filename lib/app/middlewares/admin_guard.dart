import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';

/// Sem sessão → manda para o login com `?next=` para voltar depois.
///
/// É só UX: a proteção real dos dados é o RLS/`is_admin()` no banco
/// (pendência de segurança #4). A tela do admin ainda confirma `is_admin()`.
class AdminGuard extends GetMiddleware {
  AdminGuard() : super(priority: 0);

  @override
  RouteSettings? redirect(String? route) {
    if (Get.find<AuthController>().hasSession) return null;
    return RouteSettings(name: AppRoutes.adminLoginPath(next: route));
  }
}
