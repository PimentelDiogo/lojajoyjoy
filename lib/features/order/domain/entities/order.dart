import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending('Aguardando confirmação'),
  confirmed('Confirmado'),
  cancelled('Cancelado'),
  expired('Expirado');

  const OrderStatus(this.label);
  final String label;
}

enum DeliveryMethod {
  pickup('Retirar com a Ana'),
  delivery('Entregar no meu endereço');

  const DeliveryMethod(this.label);
  final String label;
}

enum PaymentMethod {
  pix('Pix'),
  card('Cartão'),
  cash('Dinheiro');

  const PaymentMethod(this.label);
  final String label;
}

/// Item do pedido como o SERVIDOR devolveu (preço e nome do banco).
class OrderItem extends Equatable {
  const OrderItem({
    required this.productName,
    required this.size,
    required this.colorName,
    required this.unitPrice,
    required this.quantity,
    this.note,
  });

  final String productName;
  final String size;
  final String colorName;
  final num unitPrice;
  final int quantity;
  final String? note;

  num get subtotal => unitPrice * quantity;

  @override
  List<Object?> get props => [
    productName,
    size,
    colorName,
    unitPrice,
    quantity,
    note,
  ];
}

class Order extends Equatable {
  const Order({
    required this.code,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.deliveryMethod,
    this.paymentMethod,
    this.customerName,
    this.customerNote,
    this.source,
    this.confirmedAt,
    this.cancelledAt,
  });

  /// Código curto e não sequencial (ex.: K7P2QX).
  final String code;
  final OrderStatus status;
  final num total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final DeliveryMethod? deliveryMethod;
  final PaymentMethod? paymentMethod;

  /// Só vêm na resposta do create_order (e para a Ana). O resumo público omite.
  final String? customerName;
  final String? customerNote;

  /// Só para a Ana: origem (`instagram`, `whatsapp`…) e datas das ações.
  final String? source;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;

  bool get canConfirm => status == OrderStatus.pending;
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [
    code,
    status,
    total,
    createdAt,
    items,
    deliveryMethod,
    paymentMethod,
    customerName,
    customerNote,
    source,
    confirmedAt,
    cancelledAt,
  ];
}

/// O que o app envia ao criar o pedido: só variante, quantidade e observação.
/// Preço, nome, tamanho e cor são definidos pelo servidor.
class CheckoutLine extends Equatable {
  const CheckoutLine({
    required this.variantId,
    required this.quantity,
    this.note,
  });

  final String variantId;
  final int quantity;
  final String? note;

  @override
  List<Object?> get props => [variantId, quantity, note];
}

class CheckoutRequest extends Equatable {
  const CheckoutRequest({
    required this.lines,
    required this.sessionId,
    required this.source,
    this.customerName,
    this.customerNote,
    this.deliveryMethod,
    this.paymentMethod,
  });

  final List<CheckoutLine> lines;
  final String sessionId;

  /// Nome do enum `traffic_source` (ex.: "instagram").
  final String source;
  final String? customerName;
  final String? customerNote;
  final DeliveryMethod? deliveryMethod;
  final PaymentMethod? paymentMethod;

  @override
  List<Object?> get props => [
    lines,
    sessionId,
    source,
    customerName,
    customerNote,
    deliveryMethod,
    paymentMethod,
  ];
}
