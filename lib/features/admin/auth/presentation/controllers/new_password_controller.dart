import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';

/// /admin/nova-senha — aberta pelo link do e-mail de recuperação. O Supabase
/// lê o token do link ao iniciar e cria a sessão de recuperação.
class NewPasswordController extends GetxController {
  NewPasswordController({required this.auth, required this.updatePassword});

  final AuthController auth;
  final UpdatePassword updatePassword;

  final RxBool isSubmitting = false.obs;
  final RxnString error = RxnString();
  final RxBool obscure = true.obs;

  String password = '';
  String confirmation = '';

  /// Sem sessão = link vencido, já usado ou aberto sem token.
  bool get hasRecoverySession => auth.hasSession;

  Future<void> submit() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;
    error.value = null;
    final result = await updatePassword((
      password: password,
      confirmation: confirmation,
    ));
    if (result.isFailure) {
      isSubmitting.value = false;
      error.value = result.fold((_) => null, (f) => f.message);
      return;
    }
    final isAdmin = await auth.ensureAdmin();
    isSubmitting.value = false;
    unawaited(
      Get.offAllNamed<void>(isAdmin ? AppRoutes.admin : AppRoutes.adminLogin),
    );
  }
}
