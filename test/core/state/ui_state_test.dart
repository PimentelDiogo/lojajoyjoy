import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/state/ui_state.dart';

void main() {
  group('UiState.fromResult', () {
    test('sucesso vira UiSuccess com os dados', () {
      final state = UiState<List<int>>.fromResult(const Success([1, 2]));

      expect(state, isA<UiSuccess<List<int>>>());
      expect((state as UiSuccess<List<int>>).data, [1, 2]);
    });

    test('sucesso vazio vira UiEmpty quando isEmpty retorna true', () {
      final state = UiState<List<int>>.fromResult(
        const Success([]),
        isEmpty: (list) => list.isEmpty,
      );

      expect(state, isA<UiEmpty<List<int>>>());
    });

    test('falha vira UiFailure com a Failure', () {
      final state = UiState<int>.fromResult(const Failed(NetworkFailure()));

      expect(state, isA<UiFailure<int>>());
      expect((state as UiFailure<int>).failure, const NetworkFailure());
    });
  });

  test('isLoading só é verdadeiro para UiLoading', () {
    expect(const UiLoading<int>().isLoading, isTrue);
    expect(const UiIdle<int>().isLoading, isFalse);
  });
}
