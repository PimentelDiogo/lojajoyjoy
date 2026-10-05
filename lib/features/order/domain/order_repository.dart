import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';

abstract interface class OrderRepository {
  /// Cria o pedido no servidor (preços e estoque validados lá).
  Future<Result<Order>> createOrder(CheckoutRequest request);

  /// Resumo do pedido pelo código. `NotFoundFailure` se não existir.
  Future<Result<Order>> getOrder(String code);
}
