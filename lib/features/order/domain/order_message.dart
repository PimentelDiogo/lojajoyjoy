import 'package:joyjoy/core/utils/currency.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';

/// Monta a mensagem do pedido para o WhatsApp da Ana (ADR-0005).
///
/// Usa SÓ os dados devolvidos pelo servidor. Texto livre (nome, observações,
/// nomes de produto) passa por [sanitize]: sem `* _ ~ \`` (formatação do
/// WhatsApp) e sem quebras de linha — o cliente não consegue forjar linhas
/// como "Total: R$ 0,00" na mensagem.
abstract final class OrderMessage {
  static String build({
    required Order order,
    required String greeting,
    required Uri orderUrl,
  }) {
    final lines = <String>[
      sanitize(greeting),
      '',
      '🧾 Pedido #${order.code}',
      '',
    ];

    for (final (index, item) in order.items.indexed) {
      lines
        ..add('${index + 1}) ${sanitize(item.productName)}')
        ..add(
          '   Tam: ${sanitize(item.size)} | Cor: ${sanitize(item.colorName)}'
          ' | Qtd: ${item.quantity} | ${Currency.format(item.subtotal)}',
        );
      final note = sanitize(item.note ?? '');
      if (note.isNotEmpty) lines.add('   Obs: $note');
    }

    lines
      ..add('')
      ..add('💰 Total: ${Currency.format(order.total)}');

    final name = sanitize(order.customerName ?? '');
    if (name.isNotEmpty) lines.add('👤 Nome: $name');
    if (order.deliveryMethod != null) {
      lines.add('🚚 Entrega: ${order.deliveryMethod!.label}');
    }
    if (order.paymentMethod != null) {
      lines.add('💳 Pagamento: ${order.paymentMethod!.label}');
    }
    final note = sanitize(order.customerNote ?? '');
    if (note.isNotEmpty) lines.add('📝 Obs: $note');

    lines
      ..add('')
      ..add('🔗 Ver pedido: $orderUrl');
    return lines.join('\n');
  }

  static final _formatting = RegExp('[*_~`]');
  static final _whitespace = RegExp(r'\s+');

  /// Remove formatação do WhatsApp e quebras de linha; colapsa espaços.
  static String sanitize(String text) =>
      text.replaceAll(_formatting, '').replaceAll(_whitespace, ' ').trim();
}
