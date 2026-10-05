import 'package:equatable/equatable.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/stock_status.dart';

/// Peça como aparece no grid da vitrine (resumo, sem variantes detalhadas).
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.gender,
    required this.price,
    required this.totalStock,
    this.compareAtPrice,
    this.coverImageUrl,
    this.categoryId,
    this.isFeatured = false,
  });

  final String id;
  final String name;
  final String slug;
  final Gender gender;
  final num price;

  /// Preço "de" (riscado). Só é exibido quando maior que [price].
  final num? compareAtPrice;

  /// URL pública da foto de capa. Null = sem foto (placeholder).
  final String? coverImageUrl;
  final String? categoryId;
  final bool isFeatured;

  /// Soma do estoque das variantes ativas.
  final int totalStock;

  bool get hasDiscount => compareAtPrice != null && compareAtPrice! > price;

  /// Desconto em % arredondado (ex.: 23 para "-23%"). 0 sem desconto.
  int get discountPercent =>
      hasDiscount ? ((1 - price / compareAtPrice!) * 100).round() : 0;

  StockStatus stockStatus(int lowThreshold) =>
      StockStatus.from(totalStock: totalStock, lowThreshold: lowThreshold);

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    gender,
    price,
    compareAtPrice,
    coverImageUrl,
    categoryId,
    isFeatured,
    totalStock,
  ];
}
