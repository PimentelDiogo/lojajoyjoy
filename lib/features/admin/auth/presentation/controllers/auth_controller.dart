import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';

/// Sessão da Ana (global). O app usa isso só para UX (guard, menus):
/// quem protege os dados é o banco (RLS + `is_admin()`).
class AuthController extends GetxController {
  AuthController({
    required this.repository,
    required this.signInUseCase,
    required this.getCurrentAdmin,
    required this.signOutUseCase,
  });

  final AuthRepository repository;
  final SignIn signInUseCase;
  final GetCurrentAdmin getCurrentAdmin;
  final SignOut signOutUseCase;

  final Rxn<AdminUser> admin = Rxn<AdminUser>();

  /// Há sessão salva (síncrono, usado pelo `AdminGuard`).
  bool get hasSession => repository.hasSession;
  bool get isAdmin => admin.value != null;

  /// Login. Devolve a falha (mensagem pronta) ou null em caso de sucesso.
  Future<Failure?> signIn({
    required String email,
    required String password,
  }) async {
    final result = await signInUseCase(
      SignInParams(email: email, password: password),
    );
    return result.fold(
      (user) {
        admin.value = user;
        return null;
      },
      (failure) {
        admin.value = null;
        return failure;
      },
    );
  }

  /// Confirma no servidor que a sessão salva ainda é de admin.
  Future<bool> ensureAdmin() async {
    if (isAdmin) return true;
    final result = await getCurrentAdmin(const NoParams());
    admin.value = result.fold((user) => user, (_) => null);
    return isAdmin;
  }

  Future<void> signOut() async {
    admin.value = null;
    await signOutUseCase();
  }
}
