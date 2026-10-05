import 'package:equatable/equatable.dart';
import 'package:joyjoy/core/errors/result.dart';

/// Contrato de caso de uso: uma classe = uma ação de negócio.
///
/// Controllers (presentation) chamam use cases; use cases chamam repositórios
/// (contratos do domain). Nada aqui conhece Flutter, GetX ou Supabase.
// ignore: one_member_abstracts — contrato explícito da Clean Architecture.
abstract interface class UseCase<Output, Params> {
  Future<Result<Output>> call(Params params);
}

/// Parâmetro para use cases que não recebem nada.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
