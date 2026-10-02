import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/services/supabase_error_mapper.dart';
import 'package:joyjoy/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:joyjoy/features/catalog/data/models/catalog_models.dart';
import 'package:joyjoy/features/catalog/data/repositories/catalog_repositories_impl.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

JsonMap productRow({
  List<JsonMap> images = const [],
  List<JsonMap> variants = const [],
  Object? price = 189.9,
  Object? compareAt,
}) => {
  'id': 'p1',
  'name': 'Vestido Midi',
  'slug': 'vestido-midi',
  'gender': 'feminino',
  'base_price': price,
  'compare_at_price': compareAt,
  'is_featured': true,
  'category_id': 'c1',
  'product_images': images,
  'product_variants': variants,
};

String url(String path) => 'https://cdn/$path';

class _FakeRemote implements CatalogRemoteDataSource {
  Exception? error;
  List<JsonMap> products = [];
  List<JsonMap> categories = [];

  @override
  Future<List<JsonMap>> fetchProducts(ProductQuery query) async {
    if (error != null) throw error!;
    return products;
  }

  @override
  Future<List<JsonMap>> fetchCategories(Gender gender) async {
    if (error != null) throw error!;
    return categories;
  }

  @override
  String publicImageUrl(String storagePath) => url(storagePath);
}

void main() {
  group('CatalogModels.productFromJson', () {
    test('capa = imagem de menor position', () {
      final product = CatalogModels.productFromJson(
        productRow(
          images: [
            {'storage_path': 'p1/b.jpg', 'position': 1},
            {'storage_path': 'p1/a.jpg', 'position': 0},
          ],
        ),
        imageUrl: url,
      );

      expect(product.coverImageUrl, 'https://cdn/p1/a.jpg');
    });

    test('sem imagens = sem capa (placeholder)', () {
      expect(
        CatalogModels.productFromJson(
          productRow(),
          imageUrl: url,
        ).coverImageUrl,
        isNull,
      );
    });

    test('estoque soma só variantes ativas', () {
      final product = CatalogModels.productFromJson(
        productRow(
          variants: [
            {'stock_qty': 3, 'is_active': true},
            {'stock_qty': 2, 'is_active': true},
            {'stock_qty': 9, 'is_active': false},
          ],
        ),
        imageUrl: url,
      );

      expect(product.totalStock, 5);
    });

    test('aceita numeric como texto (PostgREST)', () {
      final product = CatalogModels.productFromJson(
        productRow(price: '98.00', compareAt: '129.90'),
        imageUrl: url,
      );

      expect(product.price, 98);
      expect(product.compareAtPrice, 129.9);
      expect(product.gender, Gender.feminino);
      expect(product.isFeatured, isTrue);
    });

    test('numeric inválido vira FormatException', () {
      expect(
        () => CatalogModels.productFromJson(
          productRow(price: true),
          imageUrl: url,
        ),
        throwsFormatException,
      );
    });
  });

  group('repositórios', () {
    late _FakeRemote remote;
    setUp(() => remote = _FakeRemote());

    test('ProductRepositoryImpl converte as linhas em Product', () async {
      remote.products = [productRow()];

      final result = await ProductRepositoryImpl(
        remote,
      ).getProducts(const ProductQuery());

      expect(
        (result as Success<List<Product>>).value.single.slug,
        'vestido-midi',
      );
    });

    test('erro do Postgres vira ServerFailure com o código', () async {
      remote.error = const PostgrestException(message: 'boom', code: '42P01');

      final result = await ProductRepositoryImpl(
        remote,
      ).getProducts(const ProductQuery());

      final failure = (result as Failed).failure;
      expect(failure, isA<ServerFailure>());
      expect(failure.code, '42P01');
      expect(failure.message, isNot(contains('boom'))); // nada técnico na tela
    });

    test('erro de rede vira NetworkFailure', () async {
      remote.error = Exception('socket');

      final result = await CategoryRepositoryImpl(
        remote,
      ).getCategories(Gender.feminino);

      expect((result as Failed).failure, isA<NetworkFailure>());
    });

    test('CategoryRepositoryImpl converte categorias', () async {
      remote.categories = [
        {
          'id': 'c1',
          'name': 'Vestidos',
          'slug': 'vestidos',
          'gender': 'feminino',
        },
      ];

      final result = await CategoryRepositoryImpl(
        remote,
      ).getCategories(Gender.feminino);

      expect((result as Success<List<Category>>).value.single.name, 'Vestidos');
    });
  });

  test('mapSupabaseError cobre auth, storage e formato', () {
    expect(
      mapSupabaseError(const AuthException('x', code: 'bad')),
      isA<UnauthorizedFailure>(),
    );
    expect(mapSupabaseError(const StorageException('x')), isA<ServerFailure>());
    expect(mapSupabaseError(const FormatException()), isA<ServerFailure>());
  });
}
