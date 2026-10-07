import 'package:equatable/equatable.dart';
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
