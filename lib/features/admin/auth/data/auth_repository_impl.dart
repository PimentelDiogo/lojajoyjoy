import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  /// Mensagem genérica: não revela se o e-mail existe.
  static const invalidCredentials = UnauthorizedFailure(
    'E-mail ou senha incorretos.',
  );
  static const notAdmin = UnauthorizedFailure(
    'Este usuário não tem acesso à área da loja.',
  );

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  Future<Result<AdminUser>> signIn(SignInParams params) async {
    try {
      await _client.auth.signInWithPassword(
        email: params.email.trim(),
        password: params.password,
      );
    } on AuthException catch (error) {
      final code = error.code ?? '';
      if (code == 'invalid_credentials' || error.statusCode == '400') {
        return const Failed(invalidCredentials);
      }
      return Failed(mapSupabaseError(error));
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
    return _confirmAdmin();
  }

  @override
  Future<Result<AdminUser>> currentAdmin() async {
    if (!hasSession) return const Failed(UnauthorizedFailure());
    return _confirmAdmin();
  }

  /// A palavra final é do banco (`is_admin()`): o app nunca decide sozinho.
  Future<Result<AdminUser>> _confirmAdmin() async {
    try {
      final isAdmin = await _client.rpc<bool>('is_admin');
      final user = _client.auth.currentUser;
      if (!isAdmin || user == null) {
        await _client.auth.signOut();
        return const Failed(notAdmin);
      }
      return Success(AdminUser(id: user.id, email: user.email ?? ''));
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on Object {
      // Sem rede: a sessão local é descartada mesmo assim.
    }
  }

  @override
  Future<Result<void>> requestPasswordReset(
    String email, {
    required Uri redirectTo,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo.toString(),
      );
      return const Success(null);
    } on AuthException catch (error) {
      if (error.statusCode == '429' ||
          error.code == 'over_email_send_rate_limit') {
        return const Failed(
          ServerFailure('Muitos pedidos seguidos. Aguarde alguns minutos.'),
        );
      }
      // Outros erros (ex.: e-mail inexistente) respondem igual ao sucesso.
      return const Success(null);
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    if (!hasSession) {
      return const Failed(
        UnauthorizedFailure('Link inválido ou expirado. Peça um novo.'),
      );
    }
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return const Success(null);
    } on AuthException catch (error) {
      return Failed(switch (error.code) {
        'same_password' => const ValidationFailure(
          'A nova senha precisa ser diferente da atual.',
        ),
        'weak_password' => const ValidationFailure(
          'Senha fraca: use pelo menos 10 caracteres, com letras e números.',
        ),
        _ => const UnauthorizedFailure(
          'Link inválido ou expirado. Peça um novo.',
        ),
      });
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}
