import 'package:joyjoy/core/errors/failure.dart';

/// Erros de negócio do create_order (códigos levantados pela RPC).
final class OrderFailure extends Failure {
  const OrderFailure(
    super.message, {
    required String super.code,
    this.variantId,
  });

  factory OrderFailure.fromCode(
    String code, {
    String? variantId,
  }) => OrderFailure(
    switch (code) {
      'insufficient_stock' =>
        'Uma das peças não tem mais essa quantidade em estoque.',
      'variant_unavailable' => 'Uma das peças não está mais disponível.',
      'store_closed' => 'A loja está temporariamente fechada para pedidos.',
      'rate_limited' =>
        'Você fez vários pedidos seguidos. Aguarde um pouco ou fale com a Ana.',
      'too_many_items' => 'O carrinho tem peças demais para um pedido só.',
      'invalid_quantity' => 'Quantidade inválida em uma das peças.',
      'empty_cart' => 'Seu carrinho está vazio.',
      _ => 'Não foi possível enviar o pedido. Tente novamente.',
    },
    code: code,
    variantId: variantId,
  );

  /// Variante com problema (estoque/indisponível), quando a RPC informa.
  final String? variantId;

  static const knownCodes = {
    'insufficient_stock',
    'variant_unavailable',
    'store_closed',
    'rate_limited',
    'too_many_items',
    'invalid_quantity',
    'empty_cart',
    'invalid_session',
  };

  @override
  List<Object?> get props => [...super.props, variantId];
}
