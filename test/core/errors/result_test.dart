import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';

void main() {
  group('Result', () {
    test('Success expõe o valor no fold', () {
      const Result<int> result = Success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.fold((v) => 'ok $v', (f) => 'erro'), 'ok 42');
    });

    test('Failed expõe a falha no fold', () {
      const Result<int> result = Failed(NotFoundFailure());

      expect(result.isFailure, isTrue);
      expect(result.fold((v) => 'ok', (f) => f.message), 'Não encontrado.');
    });

    test('map transforma só o sucesso', () {
      const Result<int> ok = Success(2);
      const Result<int> fail = Failed(NetworkFailure());

      expect(ok.map((v) => v * 10), const Success(20));
      expect(fail.map((v) => v * 10), const Failed<int>(NetworkFailure()));
    });

    test('igualdade por valor', () {
      expect(const Success(1), const Success(1));
      expect(const Success(1), isNot(const Success(2)));
      expect(
        const Failed<int>(ServerFailure('x', 'code')),
        const Failed<int>(ServerFailure('x', 'code')),
      );
    });
  });

  group('Failure', () {
    test('falhas de tipos diferentes com a mesma mensagem não são iguais', () {
      expect(const ValidationFailure('x'), isNot(const ServerFailure('x')));
    });

    test('carrega o código técnico para decisões na UI', () {
      const failure = ValidationFailure(
        'Sem estoque',
        code: 'insufficient_stock',
      );

      expect(failure.code, 'insufficient_stock');
    });
  });
}
