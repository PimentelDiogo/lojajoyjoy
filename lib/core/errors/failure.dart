import 'package:equatable/equatable.dart';

/// Erro de domínio que atravessa as camadas dentro de um `Result`.
///
/// Features podem estender (ex.: `OrderFailure`) para erros específicos.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.code});

  /// Mensagem pronta para exibir ao usuário (pt-BR).
  final String message;

  /// Código técnico opcional (ex.: `insufficient_stock`), útil para decisões na UI.
  final String? code;

  @override
  List<Object?> get props => [runtimeType, message, code];
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sem conexão. Verifique sua internet.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Algo deu errado no servidor. Tente novamente.',
    String? code,
  ]) : super(code: code);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Não encontrado.']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Acesso não autorizado.']);

  const UnauthorizedFailure.withCode(String? code)
    : super('Acesso não autorizado.', code: code);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Erro inesperado.']);
}
