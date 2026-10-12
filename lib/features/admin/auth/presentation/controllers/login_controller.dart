import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/utils/safe_redirect.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';

class LoginController extends GetxController {
  LoginController({required this.auth, required this.requestReset, this.next});

  final AuthController auth;
  final RequestPasswordReset requestReset;

  /// `?next=` validado por [safeNextPath] (nunca leva para fora do site).
  final String? next;

  final RxBool isSubmitting = false.obs;
  final RxnString error = RxnString();
  final RxBool obscurePassword = true.obs;

  String email = '';
  String password = '';

  String get destination => safeNextPath(next) ?? AppRoutes.admin;

  @override
  void onInit() {
    super.onInit();
    // Já logada (sessão salva): confirma e segue direto.
    if (auth.hasSession) unawaited(_resume());
  }

  Future<void> _resume() async {
    if (await auth.ensureAdmin()) unawaited(Get.offAllNamed<void>(destination));
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;
    if (email.trim().isEmpty || password.isEmpty) {
      error.value = 'Informe e-mail e senha.';
      return;
    }
    isSubmitting.value = true;
    error.value = null;
    final failure = await auth.signIn(email: email, password: password);
    isSubmitting.value = false;
    if (failure != null) {
      error.value = failure.message;
      return;
    }
    unawaited(Get.offAllNamed<void>(destination));
  }

  /// "Esqueci minha senha": mensagem para mostrar (sucesso ou erro).
  /// O texto de sucesso é o mesmo exista ou não o e-mail.
  Future<String> sendPasswordReset(String email) async {
    final result = await requestReset(email);
    return result.fold(
      (_) =>
          'Se este e-mail tiver acesso, enviamos um link para criar uma nova '
          'senha. Confira também a caixa de spam.',
      (failure) => failure.message,
    );
  }
}
