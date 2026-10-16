import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/admin/settings/domain/admin_settings.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// Tela de Configurações (ADR-0014): liga/desliga o modo de auditoria de
/// estoque. Lê o estado atual do `StoreController` global (a mesma
/// configuração que a vitrine usa) e atualiza ele direto com a resposta da
/// RPC — sem precisar recarregar a página pra refletir em todo lugar.
class AdminSettingsController extends GetxController {
  AdminSettingsController({
    required this.store,
    required this.startStockAudit,
    required this.stopStockAudit,
  });

  final StoreController store;
  final StartStockAudit startStockAudit;
  final StopStockAudit stopStockAudit;

  final RxBool isSaving = false.obs;

  bool get inStockAudit => store.settings.value?.inStockAudit ?? false;

  Future<Failure?> start(int minutes) async {
    if (isSaving.value) return null;
    isSaving.value = true;
    final result = await startStockAudit(minutes);
    isSaving.value = false;
    return switch (result) {
      Success(:final value) => _apply(value),
      Failed(:final failure) => failure,
    };
  }

  Future<Failure?> stop() async {
    if (isSaving.value) return null;
    isSaving.value = true;
    final result = await stopStockAudit(const NoParams());
    isSaving.value = false;
    return switch (result) {
      Success(:final value) => _apply(value),
      Failed(:final failure) => failure,
    };
  }

  Failure? _apply(StoreSettings value) {
    store.settings.value = value;
    return null;
  }
}
