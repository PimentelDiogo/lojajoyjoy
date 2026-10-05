@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:joyjoy/features/catalog/data/repositories/catalog_repositories_impl.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/store/data/datasources/store_remote_datasource.dart';
import 'package:joyjoy/features/store/data/repositories/store_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Valida as queries reais (sintaxe PostgREST + RLS) contra o seed local.
void main() {
  late SupabaseClient client;
  late ProductRepositoryImpl products;
  late CategoryRepositoryImpl categories;

  setUpAll(() {
    final env =
        jsonDecode(File('env/local.json').readAsStringSync())
            as Map<String, dynamic>;
    client = SupabaseClient(
      env['SUPABASE_URL'] as String,
      env['SUPABASE_ANON_KEY'] as String,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final remote = CatalogRemoteDataSourceImpl(client);
    products = ProductRepositoryImpl(remote);
    categories = CategoryRepositoryImpl(remote);
  });

  tearDownAll(() => client.dispose());

  T ok<T>(Result<T> result) => (result as Success<T>).value;

  test('Feminino traz peças femininas + unissex, nunca inativas', () async {
    final result = await products.getProducts(
      const ProductQuery(gender: Gender.feminino),
    );
    final items = ok(result);

    expect(items, isNotEmpty);
    expect(
      items.every(
        (p) => p.gender == Gender.feminino || p.gender == Gender.unissex,
      ),
      isTrue,
    );
    expect(
      items.map((p) => p.slug),
      isNot(contains('camisa-linho-colecao-passada')),
    );
  });

  test('Masculino não traz peças femininas', () async {
    final items = ok(
      await products.getProducts(const ProductQuery(gender: Gender.masculino)),
    );

    expect(
      items.map((p) => p.slug),
      containsAll(['camisa-oxford', 'bermuda-sarja']),
    );
    expect(items.where((p) => p.gender == Gender.feminino), isEmpty);
  });

  test('estoque somado das variantes e preço riscado vêm do banco', () async {
    final items = ok(
      await products.getProducts(const ProductQuery(gender: Gender.feminino)),
    );
    final midi = items.firstWhere((p) => p.slug == 'vestido-midi-linho');
    final tule = items.firstWhere((p) => p.slug == 'vestido-tule-alcinha');

    expect(midi.totalStock, 3 + 1 + 0 + 4);
    expect(tule.compareAtPrice, 129.90);
    expect(tule.hasDiscount, isTrue);
  });

  test('ordenação por menor preço', () async {
    final items = ok(
      await products.getProducts(
        const ProductQuery(gender: Gender.feminino, sort: ProductSort.priceAsc),
      ),
    );
    final prices = items.map((p) => p.price).toList();

    expect(prices, [...prices]..sort());
  });

  test('paginação por offset/limit sem repetir peças', () async {
    final first = ok(
      await products.getProducts(
        const ProductQuery(gender: Gender.feminino, limit: 2),
      ),
    );
    final second = ok(
      await products.getProducts(
        const ProductQuery(gender: Gender.feminino, limit: 2, offset: 2),
      ),
    );

    expect(first, hasLength(2));
    expect(second, isNotEmpty);
    expect(
      first
          .map((p) => p.id)
          .toSet()
          .intersection(second.map((p) => p.id).toSet()),
      isEmpty,
    );
  });

  test('destaques vêm de todas as seções', () async {
    final items = ok(
      await products.getProducts(const ProductQuery(featuredOnly: true)),
    );

    expect(items.every((p) => p.isFeatured), isTrue);
    expect(
      items.map((p) => p.gender).toSet(),
      containsAll([Gender.feminino, Gender.masculino]),
    );
  });

  test('categorias do Masculino incluem as unissex, em ordem', () async {
    final result = await categories.getCategories(Gender.masculino);
    final slugs = ok(result).map((c) => c.slug).toList();

    expect(slugs, ['camisas', 'bermudas', 'camisetas', 'calcas']);
  });

  test(
    'detalhe por slug: variantes ativas, cores e tamanhos ordenados',
    () async {
      final detail = ok(await products.getProductBySlug('vestido-midi-linho'));

      expect(detail.colors.map((c) => c.name), containsAll(['Rosa', 'Areia']));
      expect(detail.variantsOf('Rosa').map((v) => v.size), ['P', 'M', 'G']);
      expect(detail.variantFor(colorName: 'Rosa', size: 'G')?.inStock, isFalse);
      expect(detail.description, contains('Linho'));
    },
  );

  test('detalhe de produto inativo ou inexistente = NotFoundFailure', () async {
    for (final slug in ['camisa-linho-colecao-passada', 'nao-existe']) {
      final result = await products.getProductBySlug(slug);
      expect((result as Failed).failure, isA<NotFoundFailure>(), reason: slug);
    }
  });

  test('configuração da loja tem o WhatsApp da Ana', () async {
    final result = await StoreRepositoryImpl(
      StoreRemoteDataSourceImpl(client),
    ).getSettings();
    final settings = ok(result);

    expect(settings.whatsappNumber, '5581986323686');
    expect(settings.isOpen, isTrue);
  });
}
