import 'package:equatable/equatable.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

enum ProductSort {
  newest('Novidades'),
  priceAsc('Menor preço'),
  priceDesc('Maior preço');

  const ProductSort(this.label);
  final String label;
}

/// Filtro de busca de produtos da vitrine.
class ProductQuery extends Equatable {
  const ProductQuery({
    this.gender,
    this.categoryId,
    this.sort = ProductSort.newest,
    this.offset = 0,
    this.limit = defaultPageSize,
    this.featuredOnly = false,
  });

  static const defaultPageSize = 20;

  /// Null = todas as seções. Feminino/Masculino incluem os unissex.
  final Gender? gender;
  final String? categoryId;
  final ProductSort sort;
  final int offset;
  final int limit;
  final bool featuredOnly;

  ProductQuery nextPage() => ProductQuery(
    gender: gender,
    categoryId: categoryId,
    sort: sort,
    offset: offset + limit,
    limit: limit,
    featuredOnly: featuredOnly,
  );

  @override
  List<Object?> get props => [
    gender,
    categoryId,
    sort,
    offset,
    limit,
    featuredOnly,
  ];
}
