@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/admin/orders/data/admin_order_repository_impl.dart';
import 'package:joyjoy/features/admin/orders/domain/admin_orders.dart';
import 'package:joyjoy/features/order/data/order_repository_impl.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Fluxo completo (Marco 2): cliente pede → Ana confirma (estoque baixa) →
/// Ana cancela (estoque volta). Supabase local com o seed.
void main() {
  late Map<String, dynamic> env;

  setUpAll(() {
    env =
        jsonDecode(File('env/local.json').readAsStringSync())
            as Map<String, dynamic>;
  });

  SupabaseClient newClient() => SupabaseClient(
    env['SUPABASE_URL'] as String,
    env['SUPABASE_ANON_KEY'] as String,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  test('cliente pede, Ana confirma e depois cancela', () async {
    final customer = newClient();
    final ana = newClient();
    await ana.auth.signInWithPassword(
      email: 'ana@joyjoy.com.br',
      password: 'joy123',
    );
    final anaOrders = OrderRepositoryImpl(OrderRemoteDataSourceImpl(ana));

    final variant = await ana
        .from('product_variants')
        .select('id, stock_qty')
        .eq('sku', 'VML-P-ROS')
        .single();
    final stockBefore = variant['stock_qty'] as int;

    // Cliente (anon) cria o pedido: estoque ainda NÃO baixa.
    final created =
        await OrderRepositoryImpl(
          OrderRemoteDataSourceImpl(customer),
        ).createOrder(
          CheckoutRequest(
            lines: [
              CheckoutLine(variantId: variant['id'] as String, quantity: 1),
            ],
            sessionId: const Uuid().v4(),
            source: 'instagram',
            customerName: 'Cliente Integração',
          ),
        );
    final code = (created as Success<Order>).value.code;

    Future<int> stock() async =>
        (await ana
                .from('product_variants')
                .select('stock_qty')
                .eq('id', variant['id'] as String)
                .single())['stock_qty']
            as int;
    expect(await stock(), stockBefore);

    // Cliente não consegue confirmar.
    final denied = await OrderRepositoryImpl(
      OrderRemoteDataSourceImpl(customer),
    ).confirmOrder(code);
    expect(denied.isFailure, isTrue);

    // Ana vê o pedido na lista.
    final list =
        (await AdminOrderRepositoryImpl(ana).listOrders()
                as Success<List<AdminOrderSummary>>)
            .value;
    final summary = list.firstWhere((o) => o.code == code);
    expect(summary.status, OrderStatus.pending);
    expect(summary.customerName, 'Cliente Integração');
    expect(summary.itemCount, 1);

    final confirmed =
        (await anaOrders.confirmOrder(code) as Success<Order>).value;
    expect(confirmed.status, OrderStatus.confirmed);
    expect(confirmed.confirmedAt, isNotNull);
    expect(await stock(), stockBefore - 1);

    // Confirmar de novo não baixa outra vez.
    await anaOrders.confirmOrder(code);
    expect(await stock(), stockBefore - 1);

    final cancelled =
        (await anaOrders.cancelOrder(code) as Success<Order>).value;
    expect(cancelled.status, OrderStatus.cancelled);
    expect(await stock(), stockBefore);

    final moves = await ana
        .from('stock_movements')
        .select('delta, reason')
        .eq('variant_id', variant['id'] as String)
        .order('created_at', ascending: true); // padrão do supabase-dart é desc
    expect(
      moves
          .map((m) => '${m['reason']}:${m['delta']}')
          .toList()
          .sublist(moves.length - 2),
      ['sale:-1', 'sale_cancelled:1'],
    );

    await ana.auth.signOut();
    await ana.dispose();
    await customer.dispose();
  });
}
