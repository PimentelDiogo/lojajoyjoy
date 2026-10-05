import 'package:joyjoy/features/cart/domain/entities/cart.dart';

/// (De)serialização do carrinho salvo no navegador.
abstract final class CartItemModel {
  static Map<String, dynamic> toJson(CartItem item) => {
    'variant_id': item.variantId,
    'slug': item.productSlug,
    'name': item.productName,
    'size': item.size,
    'color': item.colorName,
    'color_hex': item.colorHex,
    'image': item.imageUrl,
    'price': item.unitPrice,
    'qty': item.quantity,
    'max': item.maxQuantity,
    'note': item.note,
  };

  static CartItem fromJson(Map<String, dynamic> json) => CartItem(
    variantId: json['variant_id'] as String,
    productSlug: json['slug'] as String,
    productName: json['name'] as String,
    size: json['size'] as String,
    colorName: json['color'] as String,
    colorHex: json['color_hex'] as String?,
    imageUrl: json['image'] as String?,
    unitPrice: json['price'] as num,
    quantity: (json['qty'] as num).toInt(),
    maxQuantity: (json['max'] as num).toInt(),
    note: json['note'] as String?,
  );
}
