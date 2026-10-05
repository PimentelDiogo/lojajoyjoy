@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/order/data/order_repository_impl.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/entities/order_failure.dart';
import 'package:joyjoy/features/tracking/data/tracking_repository_impl.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// create_order / get_order_public / track_visit de verdade (seed local).
void main() {
  late SupabaseClient client;
  late OrderRepositoryImpl orders;

  setUpAll(() {
    final env =
        jsonDecode(File('env/local.json').readAsStringSync())
            as Map<String, dynamic>;
    client = SupabaseClient(
      env['SUPABASE_URL'] as String,
      env['SUPABASE_ANON_KEY'] as String,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    orders = OrderRepositoryImpl(OrderRemoteDataSourceImpl(client));
  });

  tearDownAll(() => client.dispose());

  Future<String> variantId(String sku) async =>
      (await client
              .from('product_variants')
              .select('id')
              .eq('sku', sku)
              .single())['id']
          as String;

  test('cria pedido com preço do servidor e lê o resumo público', () async {
    final result = await orders.createOrder(
      CheckoutRequest(
        lines: [
          CheckoutLine(
            variantId: await variantId('VML-P-ROS'),
            quantity: 2,
            note: 'barra',
          ),
        ],
        sessionId: const Uuid().v4(),
        source: 'whatsapp',
        customerName: 'Teste Integração',
        deliveryMethod: DeliveryMethod.pickup,
      ),
    );
    final order = (result as Success<Order>).value;

    expect(order.code, matches(RegExp(r'^[2-9A-HJ-NP-Z]{6}$')));
    expect(order.total, 379.8);
    expect(order.customerName, 'Teste Integração');
    expect(order.items.single.note, 'barra');

    final public =
        (await orders.getOrder(order.code.toLowerCase()) as Success<Order>)
            .value;
    expect(public.code, order.code);
    expect(public.customerName, isNull); // resumo público sem dados do cliente
    expect(public.items.single.note, isNull);
    expect(public.status, OrderStatus.pending);
  });

  test('estoque insuficiente vira OrderFailure com a variante', () async {
    final id = await variantId('VML-G-ROS'); // estoque 0
    final result = await orders.createOrder(
      CheckoutRequest(
        lines: [CheckoutLine(variantId: id, quantity: 1)],
        sessionId: const Uuid().v4(),
        source: 'site',
      ),
    );

    final failure = (result as Failed).failure as OrderFailure;
    expect(failure.code, 'insufficient_stock');
    expect(failure.variantId, id);
  });

  test('anon não lê a tabela de pedidos direto', () async {
    final rows = await client.from('orders').select('id');
    expect(rows, isEmpty);
  });

  test('track_visit registra sem erro (e repetir é ok)', () async {
    final repo = TrackingRepositoryImpl(client);
    final session = const Uuid().v4();
    const detection = SourceDetection(
      source: TrafficSource.instagram,
      campaign: 'teste',
    );

    for (var i = 0; i < 2; i++) {
      final result = await repo.trackVisit(
        sessionId: session,
        detection: detection,
        landingPath: '/',
        deviceType: 'mobile',
      );
      expect(result.isSuccess, isTrue);
    }
  });
}
