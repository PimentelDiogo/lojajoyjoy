import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/store/domain/entities/store_settings.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';

/// Configuração da loja, carregada uma vez e compartilhada por todas as telas
/// (recado, loja fechada, WhatsApp, limite de "Últimas unidades").
class StoreController extends GetxController {
  StoreController({required this.getStoreSettings});

  final GetStoreSettings getStoreSettings;

  /// Null enquanto carrega ou se falhar (a vitrine continua funcionando).
  final Rxn<StoreSettings> settings = Rxn<StoreSettings>();

  static const defaultLowStockThreshold = 2;

  int get lowStockThreshold =>
      settings.value?.lowStockThreshold ?? defaultLowStockThreshold;

  /// Loja aberta enquanto não soubermos o contrário.
  bool get isOpen => settings.value?.isOpen ?? true;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    final result = await getStoreSettings(const NoParams());
    result.fold((value) => settings.value = value, (_) {});
  }
}
