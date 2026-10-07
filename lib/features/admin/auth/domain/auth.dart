import 'package:equatable/equatable.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';

/// Pessoa logada com acesso ao admin (está em `admin_users`).
class AdminUser extends Equatable {
  const AdminUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email];
}

abstract interface class AuthRepository {
  /// Há sessão salva no navegador (ainda não confirma se é admin).
  bool get hasSession;

  /// Login + confirmação de `is_admin()`. Não admin → sai e falha.
  Future<Result<AdminUser>> signIn(SignInParams params);

  /// Confirma a sessão atual no servidor (`is_admin()`).
  Future<Result<AdminUser>> currentAdmin();

  Future<void> signOut();

  /// Envia o link de "nova senha" para o e-mail. Mesmo resultado exista ou
  /// não o e-mail (não revela quem tem conta).
  Future<Result<void>> requestPasswordReset(
    String email, {
    required Uri redirectTo,
  });

  /// Troca a senha da sessão atual (aberta pelo link do e-mail).
  Future<Result<void>> updatePassword(String newPassword);
}

/// Regras da senha nova (iguais às do Supabase Auth: ≥ 10, letras e números).
abstract final class PasswordRules {
  static const minLength = 10;

  /// Mensagem de erro, ou null se a senha serve.
  static String? validate(String password, String confirmation) {
    if (password.length < minLength) {
      return 'A senha precisa de pelo menos $minLength caracteres.';
    }
    if (!RegExp('[A-Za-z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      return 'Use letras e números na senha.';
    }
    if (password != confirmation) return 'As senhas não são iguais.';
    return null;
  }
}

class RequestPasswordReset implements UseCase<void, String> {
  RequestPasswordReset(this._repository, {required this.redirectTo});
  final AuthRepository _repository;

  /// Página `/admin/nova-senha` (URL absoluta do site).
  final Uri redirectTo;

  @override
  Future<Result<void>> call(String email) {
    final value = email.trim();
    if (!value.contains('@') || value.length < 5) {
      return Future.value(
        const Failed(ValidationFailure('Informe um e-mail válido.')),
      );
    }
    return _repository.requestPasswordReset(value, redirectTo: redirectTo);
  }
}

class UpdatePassword
    implements UseCase<void, ({String password, String confirmation})> {
  UpdatePassword(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(({String password, String confirmation}) params) {
    final error = PasswordRules.validate(params.password, params.confirmation);
    if (error != null) return Future.value(Failed(ValidationFailure(error)));
    return _repository.updatePassword(params.password);
  }
}

class SignIn implements UseCase<AdminUser, SignInParams> {
  SignIn(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AdminUser>> call(SignInParams params) =>
      _repository.signIn(params);
}

class GetCurrentAdmin implements UseCase<AdminUser, NoParams> {
  GetCurrentAdmin(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AdminUser>> call(NoParams params) => _repository.currentAdmin();
}

class SignOut {
  SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}
