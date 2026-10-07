import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/auth_controller.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/usecases/order_usecases.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

enum OrderAction { confirm, cancel }

/// Página do pedido (/pedido/:code). Para a cliente: resumo + WhatsApp.
/// Para a Ana logada: Confirmar venda (baixa estoque) e Cancelar.
class OrderController extends GetxController {
  OrderController({
    required this.code,
    required this.getOrder,
    required this.confirmOrder,
    required this.cancelOrder,
    required this.store,
    required this.launcher,
    required this.auth,
    this.justCreated = false,
  });

  final String code;
  final GetOrder getOrder;
  final ConfirmOrder confirmOrder;
  final CancelOrder cancelOrder;
  final StoreController store;
  final LinkLauncher launcher;

  /// Só UX: quem garante que só a Ana confirma é o `is_admin()` da RPC.
  final AuthController auth;

  /// Veio direto do checkout: mostra "Pedido enviado!".
  final bool justCreated;

  final Rx<UiState<Order>> state = Rx<UiState<Order>>(const UiIdle());
  final RxBool isAdmin = false.obs;

  /// Ação em andamento (desabilita os botões, evita toque duplo).
  final Rxn<OrderAction> acting = Rxn<OrderAction>();

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = const UiLoading();
    // Cliente comum não tem sessão: nenhuma chamada extra ao servidor.
    if (auth.hasSession) isAdmin.value = await auth.ensureAdmin();
    state.value = UiState.fromResult(await getOrder(code));
  }

  Future<Failure?> confirm() => _run(OrderAction.confirm, confirmOrder.call);

  Future<Failure?> cancel() => _run(OrderAction.cancel, cancelOrder.call);

  Future<Failure?> _run(
    OrderAction action,
    Future<Result<Order>> Function(String code) call,
  ) async {
    if (acting.value != null) return null;
    acting.value = action;
    final result = await call(code);
    acting.value = null;
    switch (result) {
      case Success(:final value):
        state.value = UiSuccess(value);
        return null;
      case Failed(:final failure):
        return failure;
    }
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
