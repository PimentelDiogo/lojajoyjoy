import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/order/data/order_repository_impl.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/domain/entities/order_failure.dart';
import 'package:joyjoy/features/order/domain/order_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class _Remote implements OrderRemoteDataSource {
  Exception? error;
  Map<String, dynamic>? created;
  Map<String, dynamic>? found;
  Map<String, dynamic>? lastParams;
  String? lastCode;

  @override
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> params) async {
    lastParams = params;
    if (error != null) throw error!;
    return created!;
  }

  @override
  Future<Map<String, dynamic>?> getOrder(String code) async {
    lastCode = code;
    if (error != null) throw error!;
    return found;
  }
}

const Map<String, dynamic> json = {
  'code': 'K7P2QX',
  'status': 'pending',
  'total': '449.70',
  'created_at': '2026-10-05T15:30:00+00:00',
  'delivery_method': 'pickup',
  'payment_method': null,
  'customer_name': 'Maria',
  'customer_note': null,
  'items': [
    {
      'product_name': 'Vestido',
      'size': 'M',
      'color_name': 'Rosa',
      'unit_price': 189.9,
      'quantity': 1,
      'note': 'barra',
    },
  ],
};

void main() {
  group('OrderMessage', () {
    final url = Uri.parse('https://joyjoy.com.br/pedido/K7P2QX');

    test('formato da mensagem com dados do servidor', () {
      final text = OrderMessage.build(
        order: fakeOrder(customerName: 'Maria'),
        greeting: 'Olá! 👋 Quero fazer este pedido:',
        orderUrl: url,
      );

      expect(text, contains('🧾 Pedido #K7P2QX'));
      expect(text, contains('1) Vestido Midi Linho'));
      expect(text, contains('Tam: G | Cor: Azul | Qtd: 2 | ${brl('259,80')}'));
      expect(text, contains('💰 Total: ${brl('449,70')}'));
      expect(text, contains('👤 Nome: Maria'));
      expect(text, contains('🚚 Entrega: Retirar com a Ana'));
      expect(text, contains('💳 Pagamento: Pix'));
      expect(
        text,
        endsWith('🔗 Ver pedido: https://joyjoy.com.br/pedido/K7P2QX'),
      );
    });

    test('nome/observação maliciosos não forjam linhas nem formatação', () {
      final text = OrderMessage.build(
        order: Order(
          code: 'K7P2QX',
          status: OrderStatus.pending,
          total: 449.7,
          createdAt: DateTime(2026),
          customerName: 'Maria\n💰 Total: R\$ 0,00',
          customerNote: '*PAGO* _já_ ~ok~',
          items: const [
            OrderItem(
              productName: 'Vestido',
              size: 'M',
              colorName: 'Rosa',
              unitPrice: 449.7,
              quantity: 1,
              note: 'x\n\n🧾 Pedido #FAKE01',
            ),
          ],
        ),
        greeting: 'Olá!',
        orderUrl: url,
      );

      final totals = text
          .split('\n')
          .where((l) => l.startsWith('💰 Total:'))
          .toList();
      expect(totals, ['💰 Total: ${brl('449,70')}']); // só a linha verdadeira
      expect(
        text.split('\n').where((l) => l.startsWith('🧾 Pedido')),
        hasLength(1),
      );
      expect(text, contains('📝 Obs: PAGO já ok'));
      expect(text, isNot(contains('*')));
    });

    test('sanitize remove formatação e quebras e colapsa espaços', () {
      expect(OrderMessage.sanitize('  a*b_c~d`e \n\t f  '), 'abcde f');
    });

    test('sem campos opcionais não mostra linhas vazias', () {
      final text = OrderMessage.build(
        order: Order(
          code: 'K7P2QX',
          status: OrderStatus.pending,
          total: 10,
          createdAt: DateTime(2026),
          items: const [
            OrderItem(
              productName: 'P',
              size: 'U',
              colorName: 'Azul',
              unitPrice: 10,
              quantity: 1,
            ),
          ],
        ),
        greeting: 'Olá!',
        orderUrl: url,
      );
      expect(text, isNot(contains('Nome:')));
      expect(text, isNot(contains('Entrega:')));
      expect(text, isNot(contains('Obs:')));
    });
  });

  group('OrderRepositoryImpl', () {
    late _Remote remote;
    setUp(() => remote = _Remote());

    test('envia só variante, quantidade e observação', () async {
      remote.created = json;
      await OrderRepositoryImpl(remote).createOrder(
        const CheckoutRequest(
          lines: [CheckoutLine(variantId: 'v1', quantity: 2, note: 'barra')],
          sessionId: 's1',
          source: 'instagram',
          deliveryMethod: DeliveryMethod.delivery,
          paymentMethod: PaymentMethod.cash,
        ),
      );

      final params = remote.lastParams!;
      expect(params['p_items'], [
        {'variant_id': 'v1', 'quantity': 2, 'note': 'barra'},
      ]);
      expect(params['p_source'], 'instagram');
      expect(params['p_delivery'], 'delivery');
      expect(params['p_payment'], 'cash');
      expect((params['p_items'] as List).single, isNot(contains('price')));
    });

    test('converte a resposta (numeric como texto, enums opcionais)', () async {
      remote.created = json;
      final result = await OrderRepositoryImpl(remote).createOrder(
        const CheckoutRequest(lines: [], sessionId: 's', source: 'site'),
      );

      final order = (result as Success<Order>).value;
      expect(order.total, 449.7);
      expect(order.deliveryMethod, DeliveryMethod.pickup);
      expect(order.paymentMethod, isNull);
      expect(order.items.single.note, 'barra');
    });

    test('erro de negócio da RPC vira OrderFailure com a variante', () async {
      remote.error = const PostgrestException(
        message: 'insufficient_stock',
        code: 'P0001',
        details: 'v1',
      );
      final result = await OrderRepositoryImpl(remote).createOrder(
        const CheckoutRequest(lines: [], sessionId: 's', source: 'site'),
      );

      final failure = (result as Failed).failure as OrderFailure;
      expect(failure.code, 'insufficient_stock');
      expect(failure.variantId, 'v1');
      expect(failure.message, contains('estoque'));
    });

    test(
      'erro desconhecido vira falha genérica (sem detalhe técnico)',
      () async {
        remote.error = const PostgrestException(
          message: 'relation x does not exist',
          code: '42P01',
        );
        final result = await OrderRepositoryImpl(remote).createOrder(
          const CheckoutRequest(lines: [], sessionId: 's', source: 'site'),
        );

        final failure = (result as Failed).failure;
        expect(failure, isA<ServerFailure>());
        expect(failure.message, isNot(contains('relation')));
      },
    );

    test('getOrder: normaliza o código e trata inexistente', () async {
      final repo = OrderRepositoryImpl(remote);
      expect(
        (await repo.getOrder(' k7p2qx ') as Failed).failure,
        isA<NotFoundFailure>(),
      );
      expect(remote.lastCode, 'K7P2QX');

      remote.found = json;
      expect(
        (await repo.getOrder('K7P2QX') as Success<Order>).value.code,
        'K7P2QX',
      );
    });
  });
}
