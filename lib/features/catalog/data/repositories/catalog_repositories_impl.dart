import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:joyjoy/features/catalog/data/models/catalog_models.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<Result<List<Product>>> getProducts(ProductQuery query) async {
    try {
      final rows = await _remote.fetchProducts(query);
      return Success(
        rows
            .map(
              (row) => CatalogModels.productFromJson(
                row,
                imageUrl: _remote.publicImageUrl,
              ),
            )
            .toList(),
      );
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<Result<List<Category>>> getCategories(Gender gender) async {
    try {
      final rows = await _remote.fetchCategories(gender);
      return Success(rows.map(CatalogModels.categoryFromJson).toList());
    } on Object catch (error) {
      return Failed(mapSupabaseError(error));
    }
  }
}
