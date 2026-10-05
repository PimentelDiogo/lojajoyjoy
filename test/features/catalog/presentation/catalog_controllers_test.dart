import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/landing_controller.dart';

import '../../../helpers/fakes.dart';

/// Repositório que só responde quando o teste libera (para testar corridas).
class _ManualRepository implements ProductRepository {
  final pending = <(ProductQuery, Completer<Result<List<Product>>>)>[];

  @override
  Future<Result<ProductDetail>> getProductBySlug(String slug) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Product>>> getProducts(ProductQuery query) {
    final completer = Completer<Result<List<Product>>>();
    pending.add((query, completer));
    return completer.future;
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  CatalogController create(ProductRepository repo, {int pageSize = 3}) =>
      Get.put(
        CatalogController(
          gender: Gender.feminino,
          getProducts: GetProducts(repo),
          getCategories: GetCategories(FakeCategoryRepository()),
          pageSize: pageSize,
        ),
      );

  group('CatalogController', () {
    test('carrega categorias e a primeira página da seção', () async {
      final repo = FakeProductRepository(fakeProducts(5));
      final controller = create(repo);
      await settle();

      expect(controller.categories, hasLength(2));
      expect(controller.products.map((p) => p.id), ['p0', 'p1', 'p2']);
      expect(controller.hasMore, isTrue);
      expect(repo.queries.first.gender, Gender.feminino);
      expect(repo.queries.first.offset, 0);
    });

    test('loadMore acrescenta a próxima página e para no fim', () async {
      final controller = create(FakeProductRepository(fakeProducts(5)));
      await settle();

      await controller.loadMore();
      expect(controller.products.map((p) => p.id), [
        'p0',
        'p1',
        'p2',
        'p3',
        'p4',
      ]);
      expect(controller.hasMore, isFalse);

      await controller.loadMore(); // não busca de novo
      expect(controller.products, hasLength(5));
    });

    test('lista vazia vira UiEmpty', () async {
      final controller = create(FakeProductRepository([]));
      await settle();

      expect(controller.state.value, isA<UiEmpty<List<Product>>>());
    });

    test('falha vira UiFailure e loadMore não roda', () async {
      final repo = FakeProductRepository()..failure = const NetworkFailure();
      final controller = create(repo);
      await settle();
      await controller.loadMore();

      expect(controller.state.value, isA<UiFailure<List<Product>>>());
      expect(repo.queries, hasLength(1));
    });

    test(
      'trocar categoria ou ordenação recarrega do início com o filtro',
      () async {
        final repo = FakeProductRepository(fakeProducts(5));
        final controller = create(repo);
        await settle();
        await controller.loadMore();

        await controller.selectCategory(fakeCategories.first);
        expect(repo.queries.last.categoryId, 'c1');
        expect(repo.queries.last.offset, 0);

        await controller.changeSort(ProductSort.priceAsc);
        expect(repo.queries.last.sort, ProductSort.priceAsc);
        expect(repo.queries.last.categoryId, 'c1');
        expect(controller.products, hasLength(3));
      },
    );

    test('repetir o mesmo filtro não refaz a busca', () async {
      final repo = FakeProductRepository();
      final controller = create(repo);
      await settle();
      final count = repo.queries.length;

      await controller.selectCategory(null);
      await controller.changeSort(ProductSort.newest);

      expect(repo.queries, hasLength(count));
    });

    test('resposta antiga é descartada quando o filtro muda no meio', () async {
      final repo = _ManualRepository();
      final controller = create(repo);
      await settle();

      unawaited(controller.selectCategory(fakeCategories.first));
      await settle();
      expect(repo.pending, hasLength(2));

      // Responde a nova primeiro, depois a antiga (atrasada).
      repo.pending[1].$2.complete(Success([fakeProduct(9)]));
      await settle();
      repo.pending[0].$2.complete(Success(fakeProducts(3)));
      await settle();

      expect(controller.products.map((p) => p.id), ['p9']);
    });
  });

  group('LandingController', () {
    test('mostra só os destaques', () async {
      final repo = FakeProductRepository([
        fakeProduct(1, featured: true),
        fakeProduct(2),
        fakeProduct(3, featured: true),
      ]);
      final controller = Get.put(
        LandingController(getFeaturedProducts: GetFeaturedProducts(repo)),
      );
      await settle();

      final state = controller.featured.value as UiSuccess<List<Product>>;
      expect(state.data.map((p) => p.id), ['p1', 'p3']);
      expect(repo.queries.single.featuredOnly, isTrue);
      expect(repo.queries.single.gender, isNull);
    });

    test('sem destaques = UiEmpty (seção some)', () async {
      final controller = Get.put(
        LandingController(
          getFeaturedProducts: GetFeaturedProducts(
            FakeProductRepository(fakeProducts(2)),
          ),
        ),
      );
      await settle();

      expect(controller.featured.value, isA<UiEmpty<List<Product>>>());
    });
  });
}
