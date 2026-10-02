import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;

abstract interface class CatalogRemoteDataSource {
  Future<List<JsonMap>> fetchProducts(ProductQuery query);
  Future<List<JsonMap>> fetchCategories(Gender gender);

  /// URL pública de um arquivo do bucket `product-images`.
  String publicImageUrl(String storagePath);
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  CatalogRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const imagesBucket = 'product-images';

  /// Produto + capa + estoque das variantes visíveis (RLS já esconde as inativas
  /// para o público; o model também filtra `is_active`).
  static const productColumns =
      'id, name, slug, gender, base_price, compare_at_price, is_featured, '
      'category_id, created_at, '
      'product_images(storage_path, position), '
      'product_variants(stock_qty, is_active)';

  @override
  Future<List<JsonMap>> fetchProducts(ProductQuery query) async {
    var filter = _client
        .from('products')
        .select(productColumns)
        .eq('is_active', true);

    if (query.gender != null) {
      filter = filter.inFilter('gender', _sectionGenders(query.gender!));
    }
    if (query.categoryId != null) {
      filter = filter.eq('category_id', query.categoryId!);
    }
    if (query.featuredOnly) {
      filter = filter.eq('is_featured', true);
    }

    final ordered = switch (query.sort) {
      ProductSort.newest => filter.order('created_at', ascending: false),
      ProductSort.priceAsc => filter.order('base_price', ascending: true),
      ProductSort.priceDesc => filter.order('base_price', ascending: false),
    };

    // `id` como desempate deixa a paginação estável.
    return ordered
        .order('id', ascending: true)
        .range(query.offset, query.offset + query.limit - 1);
  }

  @override
  Future<List<JsonMap>> fetchCategories(Gender gender) => _client
      .from('categories')
      .select('id, name, slug, gender')
      .eq('is_active', true)
      .inFilter('gender', _sectionGenders(gender))
      .order('position', ascending: true);

  @override
  String publicImageUrl(String storagePath) =>
      _client.storage.from(imagesBucket).getPublicUrl(storagePath);

  /// Feminino/Masculino também mostram as peças unissex.
  static List<String> _sectionGenders(Gender gender) => gender == Gender.unissex
      ? [Gender.unissex.name]
      : [gender.name, Gender.unissex.name];
}
