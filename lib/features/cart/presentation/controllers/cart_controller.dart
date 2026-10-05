import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/domain/usecases/cart_usecases.dart';

/// Carrinho global (badge no header, detalhe do produto, tela do carrinho).
/// As regras ficam no [Cart] (domain); aqui só aplicamos e salvamos.
class CartController extends GetxController {
  CartController({required this.loadCart, required this.saveCart});

  final LoadCart loadCart;
  final SaveCart saveCart;

  final Rx<Cart> cart = Cart.empty.obs;

  int get totalQuantity => cart.value.totalQuantity;

  @override
  void onInit() {
    super.onInit();
    cart.value = loadCart();
  }

  Future<AddToCartOutcome> add(CartItem item) async {
    final (next, outcome) = cart.value.add(item);
    await _set(next);
    return outcome;
  }

  Future<void> updateQuantity(String variantId, int quantity) =>
      _set(cart.value.updateQuantity(variantId, quantity));

  Future<void> updateNote(String variantId, String? note) =>
      _set(cart.value.updateNote(variantId, note));

  /// Remove e devolve (posição, item) para o "Desfazer".
  Future<(int, CartItem)?> remove(String variantId) async {
    final index = cart.value.items.indexWhere((i) => i.variantId == variantId);
    if (index < 0) return null;
    final item = cart.value.items[index];
    await _set(cart.value.remove(variantId));
    return (index, item);
  }

  Future<void> undoRemove(int index, CartItem item) =>
      _set(cart.value.insertAt(index, item));

  Future<void> clear() => _set(Cart.empty);

  Future<void> _set(Cart next) async {
    if (next == cart.value) return;
    cart.value = next;
    await saveCart(next);
  }
}
