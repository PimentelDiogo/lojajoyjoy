import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/entities/order_failure.dart';
import 'package:joyjoy/features/order/domain/order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Chamadas às RPCs (`create_order`, `get_order_public`). Abstração para testes.
abstract interface class OrderRemoteDataSource {
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> params);
  Future<Map<String, dynamic>?> getOrder(String code);
  Future<Map<String, dynamic>> confirmOrder(String code);
  Future<Map<String, dynamic>> cancelOrder(String code);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> params) async =>
      (await _client.rpc<dynamic>('create_order', params: params))
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>?> getOrder(String code) async =>
      (await _client.rpc<dynamic>('get_order_public', params: {'p_code': code}))
          as Map<String, dynamic>?;

  @override
  Future<Map<String, dynamic>> confirmOrder(String code) async =>
      (await _client.rpc<dynamic>('confirm_order', params: {'p_code': code}))
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> cancelOrder(String code) async =>
      (await _client.rpc<dynamic>('cancel_order', params: {'p_code': code}))
          as Map<String, dynamic>;
}

abstract final class OrderModel {
  static Map<String, dynamic> requestToParams(CheckoutRequest request) => {
    // Só variante, quantidade e observação — nada de preço/nome.
    'p_items': [
      for (final line in request.lines)
        {
          'variant_id': line.variantId,
          'quantity': line.quantity,
          if (line.note != null) 'note': line.note,
        },
    ],
    'p_session_id': request.sessionId,
    'p_source': request.source,
    'p_customer_name': request.customerName,
    'p_customer_note': request.customerNote,
    'p_delivery': request.deliveryMethod?.name,
    'p_payment': request.paymentMethod?.name,
  };

  static Order fromJson(Map<String, dynamic> json) => Order(
    code: json['code'] as String,
    status: OrderStatus.values.byName(json['status'] as String),
    total: _num(json['total']),
    createdAt: DateTime.parse(json['created_at'] as String),
    deliveryMethod: _enum(DeliveryMethod.values, json['delivery_method']),
    paymentMethod: _enum(PaymentMethod.values, json['payment_method']),
    customerName: json['customer_name'] as String?,
    customerNote: json['customer_note'] as String?,
    source: json['source'] as String?,
    confirmedAt: _date(json['confirmed_at']),
    cancelledAt: _date(json['cancelled_at']),
    items: [
      for (final item
          in (json['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        OrderItem(
          productName: item['product_name'] as String,
          size: item['size'] as String,
          colorName: item['color_name'] as String,
          unitPrice: _num(item['unit_price']),
          quantity: (item['quantity'] as num).toInt(),
          note: item['note'] as String?,
        ),
    ],
  );

  static num _num(Object? value) => switch (value) {
    final num n => n,
    final String s => num.parse(s),
    _ => throw FormatException('Valor numérico inválido: $value'),
  };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;

  static T? _enum<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<Result<Order>> createOrder(CheckoutRequest request) async {
    try {
      final json = await _remote.createOrder(
        OrderModel.requestToParams(request),
      );
      return Success(OrderModel.fromJson(json));
    } on PostgrestException catch (error) {
      // Erros de negócio levantados pela RPC: `raise exception 'insufficient_stock'`.
      if (OrderFailure.knownCodes.contains(error.message)) {
        return Failed(
          OrderFailure.fromCode(
            error.message,
            variantId: error.details as String?,
          ),
        );
      }
      return Failed(mapSupabaseError(error));
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<Order>> getOrder(String code) async {
    try {
      final json = await _remote.getOrder(code.trim().toUpperCase());
      if (json == null) {
        return const Failed(NotFoundFailure('Pedido não encontrado.'));
      }
      return Success(OrderModel.fromJson(json));
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<Order>> confirmOrder(String code) =>
      _action(() => _remote.confirmOrder(code.trim().toUpperCase()));

  @override
  Future<Result<Order>> cancelOrder(String code) =>
      _action(() => _remote.cancelOrder(code.trim().toUpperCase()));

  Future<Result<Order>> _action(
    Future<Map<String, dynamic>> Function() run,
  ) async {
    try {
      return Success(OrderModel.fromJson(await run()));
    } on PostgrestException catch (error) {
      if (OrderFailure.actionCodes.contains(error.message)) {
        return Failed(
          OrderFailure.fromActionCode(
            error.message,
            detail: switch (error.details) {
              final String text => text,
              _ => null,
            },
          ),
        );
      }
      if (error.code == '42501') {
        return const Failed(
          OrderFailure('Sua sessão expirou. Entre de novo.', code: 'forbidden'),
        );
      }
      return Failed(mapSupabaseError(error));
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}
