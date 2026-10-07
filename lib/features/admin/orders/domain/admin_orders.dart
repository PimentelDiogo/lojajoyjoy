import 'package:equatable/equatable.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';

/// Pedido na lista da Ana (/admin/pedidos).
class AdminOrderSummary extends Equatable {
  const AdminOrderSummary({
    required this.code,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.itemCount,
    this.customerName,
    this.source,
  });

  final String code;
  final OrderStatus status;
  final num total;
  final DateTime createdAt;

  /// Soma das quantidades (3 peças em 2 itens = 3).
  final int itemCount;
  final String? customerName;
  final String? source;

  @override
  List<Object?> get props => [
    code,
    status,
    total,
    createdAt,
    itemCount,
    customerName,
    source,
  ];
}

abstract interface class AdminOrderRepository {
  /// Pedidos mais recentes primeiro. Só a Ana lê (RLS `is_admin()`).
  Future<Result<List<AdminOrderSummary>>> listOrders();
}

class ListAdminOrders implements UseCase<List<AdminOrderSummary>, NoParams> {
  ListAdminOrders(this._repository);
  final AdminOrderRepository _repository;

  @override
  Future<Result<List<AdminOrderSummary>>> call(NoParams params) =>
      _repository.listOrders();
}
