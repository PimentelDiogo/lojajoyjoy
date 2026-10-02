import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';

/// Estado de tela observado pela View (`Rx<UiState<T>>` + `Obx`).
sealed class UiState<T> {
  const UiState();

  /// Converte o `Result` de um use case em estado de tela.
  ///
  /// [isEmpty] decide quando um sucesso deve virar [UiEmpty] (ex.: lista vazia).
  factory UiState.fromResult(
    Result<T> result, {
    bool Function(T value)? isEmpty,
  }) => result.fold(
    (value) =>
        (isEmpty?.call(value) ?? false) ? UiEmpty<T>() : UiSuccess<T>(value),
    UiFailure<T>.new,
  );

  bool get isLoading => this is UiLoading<T>;
}

final class UiIdle<T> extends UiState<T> {
  const UiIdle();
}

final class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

final class UiSuccess<T> extends UiState<T> {
  const UiSuccess(this.data);
  final T data;
}

final class UiEmpty<T> extends UiState<T> {
  const UiEmpty();
}

final class UiFailure<T> extends UiState<T> {
  const UiFailure(this.failure);
  final Failure failure;
}
