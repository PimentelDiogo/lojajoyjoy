import 'package:equatable/equatable.dart';

/// Uma peça no carrinho: variante (tamanho × cor) + quantidade + observação.
///
/// Guarda um "retrato" do produto no momento em que foi adicionado. O preço
/// e o estoque reais são revalidados no servidor ao criar o pedido (PR-07).
class CartItem extends Equatable {
  const CartItem({
    required this.variantId,
    required this.productSlug,
    required this.productName,
    required this.size,
    required this.colorName,
    required this.unitPrice,
    required this.quantity,
    required this.maxQuantity,
    this.colorHex,
    this.imageUrl,
    this.note,
  });

  final String variantId;
  final String productSlug;
  final String productName;
  final String size;
  final String colorName;
  final String? colorHex;
  final String? imageUrl;
  final num unitPrice;
  final int quantity;

  /// Limite desta variante (estoque no momento da adição, até [Cart.maxPerItem]).
  final int maxQuantity;

  /// Observação do cliente para esta peça (A7), ex.: "fazer barra 2 cm".
  final String? note;

  num get subtotal => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    int? maxQuantity,
    String? note,
    bool clearNote = false,
  }) => CartItem(
    variantId: variantId,
    productSlug: productSlug,
    productName: productName,
    size: size,
    colorName: colorName,
    colorHex: colorHex,
    imageUrl: imageUrl,
    unitPrice: unitPrice,
    quantity: quantity ?? this.quantity,
    maxQuantity: maxQuantity ?? this.maxQuantity,
    note: clearNote ? null : (note ?? this.note),
  );

  @override
  List<Object?> get props => [
    variantId,
    productSlug,
    productName,
    size,
    colorName,
    colorHex,
    imageUrl,
    unitPrice,
    quantity,
    maxQuantity,
    note,
  ];
}

/// Resultado de tentar adicionar uma peça.
enum AddToCartOutcome {
  /// Peça nova no carrinho.
  added,

  /// Já existia: somou a quantidade.
  merged,

  /// Somou só até o limite (estoque ou [Cart.maxPerItem]).
  limited,

  /// Já estava no limite: nada mudou.
  atLimit,

  /// Sem estoque: nada mudou.
  unavailable,
}

/// Carrinho imutável com as regras de negócio (Dart puro, sem Flutter/GetX).
class Cart extends Equatable {
  const Cart([this.items = const []]);

  static const empty = Cart();

  /// Teto por variante, mesmo com muito estoque.
  static const maxPerItem = 10;

  /// Teto de peças diferentes (mantém a mensagem do WhatsApp legível).
  static const maxDistinctItems = 20;

  static const maxNoteLength = 140;

  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  num get subtotal => items.fold<num>(0, (sum, i) => sum + i.subtotal);

  CartItem? itemFor(String variantId) {
    for (final item in items) {
      if (item.variantId == variantId) return item;
    }
    return null;
  }

  /// Adiciona [item] somando à quantidade existente da mesma variante,
  /// sem passar do limite.
  (Cart, AddToCartOutcome) add(CartItem item) {
    final limit = _limit(item.maxQuantity);
    if (limit <= 0 || item.quantity <= 0) {
      return (this, AddToCartOutcome.unavailable);
    }

    final existing = itemFor(item.variantId);
    if (existing == null) {
      if (items.length >= maxDistinctItems) {
        return (this, AddToCartOutcome.atLimit);
      }
      final quantity = item.quantity.clamp(1, limit);
      final note = _cleanNote(item.note);
      final added = item.copyWith(
        quantity: quantity,
        maxQuantity: limit,
        note: note,
        clearNote: note == null,
      );
      return (
        Cart([...items, added]),
        quantity < item.quantity
            ? AddToCartOutcome.limited
            : AddToCartOutcome.added,
      );
    }

    if (existing.quantity >= limit) return (this, AddToCartOutcome.atLimit);
    final wanted = existing.quantity + item.quantity;
    final quantity = wanted.clamp(1, limit);
    return (
      _replace(existing.copyWith(quantity: quantity, maxQuantity: limit)),
      quantity < wanted ? AddToCartOutcome.limited : AddToCartOutcome.merged,
    );
  }

  /// Nova quantidade (1..limite). Abaixo de 1, use [remove].
  Cart updateQuantity(String variantId, int quantity) {
    final item = itemFor(variantId);
    if (item == null) return this;
    return _replace(
      item.copyWith(quantity: quantity.clamp(1, _limit(item.maxQuantity))),
    );
  }

  Cart updateNote(String variantId, String? note) {
    final item = itemFor(variantId);
    if (item == null) return this;
    final clean = _cleanNote(note);
    return _replace(item.copyWith(note: clean, clearNote: clean == null));
  }

  Cart remove(String variantId) =>
      Cart(items.where((i) => i.variantId != variantId).toList());

  /// Desfazer remoção: devolve o item na mesma posição.
  Cart insertAt(int index, CartItem item) {
    if (itemFor(item.variantId) != null) return this;
    final list = [...items]..insert(index.clamp(0, items.length), item);
    return Cart(list);
  }

  Cart _replace(CartItem updated) => Cart([
    for (final i in items) i.variantId == updated.variantId ? updated : i,
  ]);

  static int _limit(int maxQuantity) =>
      maxQuantity < maxPerItem ? maxQuantity : maxPerItem;

  static String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length > maxNoteLength
        ? trimmed.substring(0, maxNoteLength)
        : trimmed;
  }

  @override
  List<Object?> get props => [items];
}
