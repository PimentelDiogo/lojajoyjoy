import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';

/// ADR-0014: modo de auditoria de estoque. Só funciona logada como admin
/// (RLS + RPC) — mesmas peças da feature `store`, vistas pelo lado de quem
/// liga/desliga em vez de quem só lê.
abstract interface class AdminSettingsRepository {
  /// 15, 30 ou 60 minutos. Devolve a configuração já atualizada.
  Future<Result<StoreSettings>> startStockAudit(int minutes);

  /// Reabre a loja e limpa o prazo. Sempre manual — nunca automático.
  Future<Result<StoreSettings>> stopStockAudit();
}

class StartStockAudit implements UseCase<StoreSettings, int> {
  StartStockAudit(this._repository);
  final AdminSettingsRepository _repository;

  static const allowedMinutes = [15, 30, 60];

  @override
  Future<Result<StoreSettings>> call(int minutes) {
    if (!allowedMinutes.contains(minutes)) {
      return Future.value(
        const Failed(ValidationFailure('Escolha 15, 30 ou 60 minutos.')),
      );
    }
    return _repository.startStockAudit(minutes);
  }
}

class StopStockAudit implements UseCase<StoreSettings, NoParams> {
  StopStockAudit(this._repository);
  final AdminSettingsRepository _repository;

  @override
  Future<Result<StoreSettings>> call(NoParams params) =>
      _repository.stopStockAudit();
}
