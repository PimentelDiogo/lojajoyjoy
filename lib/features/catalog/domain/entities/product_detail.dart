import 'package:equatable/equatable.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

/// Variante física: um tamanho numa cor ("Vestido M Rosa").
class ProductVariant extends Equatable {
  const ProductVariant({
    required this.id,
    required this.size,
    required this.colorName,
    required this.stock,
    required this.price,
    this.colorHex,
  });

  final String id;
  final String size;
  final String colorName;

  /// `#RRGGBB` para a amostra de cor. Null = mostra só o nome.
  final String? colorHex;
  final int stock;

  /// Preço efetivo (`price_override` ou o preço base do produto).
  final num price;

  bool get inStock => stock > 0;

  @override
  List<Object?> get props => [id, size, colorName, colorHex, stock, price];
}

/// Cor disponível para o produto (amostra + nome).
class ProductColor extends Equatable {
  const ProductColor({required this.name, this.hex});

  final String name;
  final String? hex;

  @override
  List<Object?> get props => [name, hex];
}

/// Página do produto: fotos, descrição e variantes.
class ProductDetail extends Equatable {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.gender,
    required this.price,
    required this.imageUrls,
    required this.variants,
    this.description,
    this.compareAtPrice,
  });

  final String id;
  final String name;
  final String slug;
  final Gender gender;
  final num price;
  final num? compareAtPrice;
  final String? description;

  /// Fotos em ordem (a primeira é a capa).
  final List<String> imageUrls;
  final List<ProductVariant> variants;

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  /// Cores na ordem em que aparecem nas variantes, sem repetir.
  List<ProductColor> get colors {
    final seen = <String>{};
    return [
      for (final v in variants)
        if (seen.add(v.colorName))
          ProductColor(name: v.colorName, hex: v.colorHex),
    ];
  }

  /// Variantes de uma cor, com tamanhos em ordem (PP → GG, 36 → 48).
  List<ProductVariant> variantsOf(String colorName) =>
      variants.where((v) => v.colorName == colorName).toList()
        ..sort((a, b) => SizeOrder.compare(a.size, b.size));

  ProductVariant? variantFor({
    required String colorName,
    required String size,
  }) {
    for (final v in variants) {
      if (v.colorName == colorName && v.size == size) return v;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    gender,
    price,
    compareAtPrice,
    description,
    imageUrls,
    variants,
  ];
}

/// Ordem natural de tamanhos: letras (PP…XGG), depois numéricos, depois o resto.
abstract final class SizeOrder {
  static const _letters = ['PP', 'P', 'M', 'G', 'GG', 'XG', 'XGG', 'EG', 'EGG'];

  static int compare(String a, String b) {
    final ra = _rank(a);
    final rb = _rank(b);
    if (ra != rb) return ra.compareTo(rb);
    return a.compareTo(b);
  }

  static int _rank(String size) {
    final upper = size.trim().toUpperCase();
    final letter = _letters.indexOf(upper);
    if (letter >= 0) return letter;
    final number = int.tryParse(upper);
    if (number != null) return 100 + number;
    return 1000; // "U", "Único" etc. no fim
  }
}
