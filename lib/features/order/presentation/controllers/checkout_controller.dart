import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/entities/order_failure.dart';
import 'package:joyjoy/features/order/domain/order_message.dart';
import 'package:joyjoy/features/order/domain/usecases/order_usecases.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:joyjoy/features/tracking/presentation/session_tracker.dart';

/// Finalizar pedido: cria no servidor → mensagem com os dados DO SERVIDOR →
/// limpa o carrinho → abre o WhatsApp da Ana (ADR-0005).
class CheckoutController extends GetxController {
  CheckoutController({
    required this.cart,
    required this.store,
    required this.tracker,
    required this.createOrder,
    required this.launcher,
    required this.env,
  });

  final CartController cart;
  final StoreController store;
  final SessionTracker tracker;
  final CreateOrder createOrder;
  final LinkLauncher launcher;
  final Env env;

  static const defaultGreeting = 'Olá! 👋 Quero fazer este pedido:';
  static const maxNameLength = 60;
  static const maxNoteLength = 300;

  final Rx<UiState<Order>> state = Rx<UiState<Order>>(const UiIdle());
  final Rxn<DeliveryMethod> delivery = Rxn<DeliveryMethod>();
  final Rxn<PaymentMethod> payment = Rxn<PaymentMethod>();
  String customerName = '';
  String customerNote = '';

  bool get isSubmitting => state.value is UiLoading;

  /// Nome da peça com problema (quando a RPC aponta a variante).
  String? get problemItemName {
    final failure = switch (state.value) {
      UiFailure(:final OrderFailure failure) => failure,
      _ => null,
    };
    final variantId = failure?.variantId;
    if (variantId == null) return null;
    final item = cart.cart.value.itemFor(variantId);
    return item == null
        ? null
        : '${item.productName} (Tam ${item.size}, ${item.colorName})';
  }

  Future<void> submit() async {
    final current = cart.cart.value;
    if (isSubmitting || current.isEmpty) return;
    if (!store.isOpen) {
      state.value = UiFailure(OrderFailure.fromCode('store_closed'));
      return;
    }

    state.value = const UiLoading();
    final result = await createOrder(
      CheckoutRequest(
        lines: [
          for (final item in current.items)
            CheckoutLine(
              variantId: item.variantId,
              quantity: item.quantity,
              note: item.note,
            ),
        ],
        sessionId: tracker.sessionId,
        source: tracker.source.name,
        customerName: _clean(customerName, maxNameLength),
        customerNote: _clean(customerNote, maxNoteLength),
        deliveryMethod: delivery.value,
        paymentMethod: payment.value,
      ),
    );

    final order = result.fold<Order?>((o) => o, (_) => null);
    if (order == null) {
      state.value = UiState.fromResult(result);
      return;
    }

    state.value = UiSuccess(order);
    final settings = store.settings.value;
    final message = OrderMessage.build(
      order: order,
      greeting: settings?.greetingMessage ?? defaultGreeting,
      // Sempre via AppRoutes.orderPath (codifica o código) — pendência PR-01 #2.
      orderUrl: env.absoluteUri(AppRoutes.orderPath(order.code)),
    );
    final whatsapp = settings == null
        ? null
        : WhatsAppLink.tryBuild(settings.whatsappNumber, message: message);

    // Só limpa o carrinho depois do pedido criado com sucesso.
    await cart.clear();
    // Primeiro a página do pedido (fica no histórico ao voltar do WhatsApp).
    unawaited(
      Get.offAllNamed<void>(AppRoutes.orderPath(order.code), arguments: true),
    );
    if (whatsapp != null) await launcher.open(whatsapp);
  }

  static String? _clean(String value, int max) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.length > max ? trimmed.substring(0, max) : trimmed;
  }
}
