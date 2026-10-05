import 'package:joyjoy/features/cart/domain/entities/cart.dart';

/// Carrinho guardado no navegador (sobrevive a recarregar a página).
abstract interface class CartRepository {
  Cart load();
  Future<void> save(Cart cart);
}
