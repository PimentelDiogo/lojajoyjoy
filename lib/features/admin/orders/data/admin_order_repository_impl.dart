import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/admin/orders/domain/admin_orders.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Leitura dos pedidos pela Ana. A escrita (confirmar/cancelar) só existe
/// nas RPCs `confirm_order` / `cancel_order` — sem UPDATE direto na tabela.
class AdminOrderRepositoryImpl implements AdminOrderRepository {
  AdminOrderRepositoryImpl(this._client);

  final SupabaseClient _client;

  static const listLimit = 200;

  @override
  Future<Result<List<AdminOrderSummary>>> listOrders() async {
    try {
      final rows = await _client
          .from('orders')
          .select(
            'code, status, total, created_at, customer_name, source, '
            'order_items(quantity)',
          )
          .order('created_at', ascending: false)
          .limit(listLimit);
      return Success(rows.map(fromJson).toList());
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }

  static AdminOrderSummary fromJson(Map<String, dynamic> json) =>
      AdminOrderSummary(
        code: json['code'] as String,
        status: OrderStatus.values.byName(json['status'] as String),
        total: switch (json['total']) {
          final num n => n,
          final String s => num.parse(s),
          _ => 0,
        },
        createdAt: DateTime.parse(json['created_at'] as String),
        customerName: json['customer_name'] as String?,
        source: json['source'] as String?,
        itemCount: (json['order_items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .fold(0, (sum, i) => sum + ((i['quantity'] as num?)?.toInt() ?? 0)),
      );
}
