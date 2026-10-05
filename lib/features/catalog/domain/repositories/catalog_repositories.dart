import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';

abstract interface class ProductRepository {
  Future<Result<List<Product>>> getProducts(ProductQuery query);

  /// Produto ativo pelo slug. `NotFoundFailure` se não existir ou estiver inativo.
  Future<Result<ProductDetail>> getProductBySlug(String slug);
}

abstract interface class CategoryRepository {
  /// Categorias ativas da seção (inclui as unissex).
  Future<Result<List<Category>>> getCategories(Gender gender);
}
