import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/domain/repositories/cart_repository.dart';

/// Carrega o carrinho salvo. Síncrono: o storage local já está em memória.
class LoadCart {
  LoadCart(this._repository);
  final CartRepository _repository;

  Cart call() => _repository.load();
}

class SaveCart {
  SaveCart(this._repository);
  final CartRepository _repository;

  Future<void> call(Cart cart) => _repository.save(cart);
}
