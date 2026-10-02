import 'package:joyjoy/core/errors/failure.dart';
import 'package:meta/meta.dart';

/// Resultado de uma operação: [Success] com valor ou [Failed] com [Failure].
///
/// Repositórios e use cases retornam `Result` — exceções não chegam à View.
@immutable
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failed<T>;

  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) => switch (this) {
    Success(:final value) => onSuccess(value),
    Failed(:final failure) => onFailure(failure),
  };

  /// Transforma o valor de sucesso mantendo a falha intacta.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Success(transform(value)),
    Failed(:final failure) => Failed(failure),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  bool operator ==(Object other) => other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is Failed<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
