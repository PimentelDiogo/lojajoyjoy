import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';

abstract interface class ProductRepository {
  Future<Result<List<Product>>> getProducts(ProductQuery query);
}

abstract interface class CategoryRepository {
  /// Categorias ativas da seção (inclui as unissex).
  Future<Result<List<Category>>> getCategories(Gender gender);
}
