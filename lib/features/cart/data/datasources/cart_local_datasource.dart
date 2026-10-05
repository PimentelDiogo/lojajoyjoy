import 'package:joyjoy/core/services/key_value_store.dart';

/// Lê/grava o JSON do carrinho no armazenamento local.
abstract interface class CartLocalDataSource {
  String? read();
  Future<void> write(String json);
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  CartLocalDataSourceImpl(this._store);

  /// Versionado: se o formato mudar, carrinhos antigos são descartados.
  static const storageKey = 'cart_v1';

  final KeyValueStore _store;

  @override
  String? read() => _store.read(storageKey);

  @override
  Future<void> write(String json) => _store.write(storageKey, json);
}
