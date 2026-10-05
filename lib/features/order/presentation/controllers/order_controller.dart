import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/usecases/order_usecases.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// Página pública do pedido (/pedido/:code). Ações da Ana chegam no PR-10.
class OrderController extends GetxController {
  OrderController({
    required this.code,
    required this.getOrder,
    required this.store,
    required this.launcher,
    this.justCreated = false,
  });

  final String code;
  final GetOrder getOrder;
  final StoreController store;
  final LinkLauncher launcher;

  /// Veio direto do checkout: mostra "Pedido enviado!".
  final bool justCreated;

  final Rx<UiState<Order>> state = Rx<UiState<Order>>(const UiIdle());

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = const UiLoading();
    state.value = UiState.fromResult(await getOrder(code));
  }

  /// Abre o WhatsApp da Ana citando o pedido.
  Future<bool> talkToStore() async {
    final number = store.settings.value?.whatsappNumber;
    final uri = number == null
        ? null
        : WhatsAppLink.tryBuild(number, message: 'Olá! Sobre o pedido #$code');
    if (uri == null) return false;
    return launcher.open(uri);
  }
}
