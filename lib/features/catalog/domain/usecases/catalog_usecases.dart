import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';

class GetProducts implements UseCase<List<Product>, ProductQuery> {
  GetProducts(this._repository);
  final ProductRepository _repository;

  @override
  Future<Result<List<Product>>> call(ProductQuery params) =>
      _repository.getProducts(params);
}

/// Destaques da landing (todas as seções, marcados pela Ana).
class GetFeaturedProducts implements UseCase<List<Product>, NoParams> {
  GetFeaturedProducts(this._repository);
  final ProductRepository _repository;

  static const limit = 12;

  @override
  Future<Result<List<Product>>> call(NoParams params) =>
      _repository.getProducts(
        const ProductQuery(featuredOnly: true, limit: limit),
      );
}

class GetCategories implements UseCase<List<Category>, Gender> {
  GetCategories(this._repository);
  final CategoryRepository _repository;

  @override
  Future<Result<List<Category>>> call(Gender params) =>
      _repository.getCategories(params);
}

class GetProductBySlug implements UseCase<ProductDetail, String> {
  GetProductBySlug(this._repository);
  final ProductRepository _repository;

  @override
  Future<Result<ProductDetail>> call(String params) =>
      _repository.getProductBySlug(params);
}
