import 'package:get/get.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';
import 'package:joyjoy/features/order/domain/order_repository.dart';
import 'package:joyjoy/features/order/domain/usecases/order_usecases.dart';
import 'package:joyjoy/features/order/presentation/controllers/checkout_controller.dart';
import 'package:joyjoy/features/order/presentation/controllers/order_controller.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:joyjoy/features/tracking/presentation/session_tracker.dart';

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CheckoutController(
        cart: Get.find<CartController>(),
        store: Get.find<StoreController>(),
        tracker: Get.find<SessionTracker>(),
        createOrder: CreateOrder(Get.find<OrderRepository>()),
        launcher: Get.find<LinkLauncher>(),
        env: Get.find<Env>(),
      ),
    );
  }
}

/// Controller com `tag` = código do pedido.
class OrderBinding extends Bindings {
  @override
  void dependencies() {
    final code = (Get.parameters['code'] ?? '').toUpperCase();
    Get.lazyPut(
      () => OrderController(
        code: code,
        getOrder: GetOrder(Get.find<OrderRepository>()),
        store: Get.find<StoreController>(),
        launcher: Get.find<LinkLauncher>(),
        justCreated: Get.arguments == true,
      ),
      tag: code,
    );
  }
}
