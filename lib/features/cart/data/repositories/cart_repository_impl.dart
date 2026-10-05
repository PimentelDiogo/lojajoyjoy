import 'dart:convert';

import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/models/cart_item_model.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/domain/repositories/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._local);

  final CartLocalDataSource _local;

  /// JSON corrompido ou de outra versão → carrinho vazio (nunca quebra a loja).
  @override
  Cart load() {
    final raw = _local.read();
    if (raw == null || raw.isEmpty) return Cart.empty;
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      var cart = Cart.empty;
      for (final json in list) {
        // Passa pelas regras do domain (limites, notas) mesmo ao carregar.
        cart = cart.add(CartItemModel.fromJson(json)).$1;
      }
      return cart;
    } on Object {
      return Cart.empty;
    }
  }

  @override
  Future<void> save(Cart cart) =>
      _local.write(jsonEncode(cart.items.map(CartItemModel.toJson).toList()));
}
