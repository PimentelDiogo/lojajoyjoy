import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';

/// Grid de uma seção (Feminino ou Masculino) com filtro, ordenação e
/// carregamento progressivo (sem paginação numerada — problema E6).
class CatalogController extends GetxController {
  CatalogController({
    required this.gender,
    required this.getProducts,
    required this.getCategories,
    this.pageSize = ProductQuery.defaultPageSize,
  });

  final Gender gender;
  final GetProducts getProducts;
  final GetCategories getCategories;
  final int pageSize;

  final Rx<UiState<List<Product>>> state = Rx<UiState<List<Product>>>(
    const UiIdle(),
  );
  final RxList<Category> categories = <Category>[].obs;
  final Rxn<Category> selectedCategory = Rxn<Category>();
  final Rx<ProductSort> sort = ProductSort.newest.obs;
  final RxBool isLoadingMore = false.obs;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// Descarta respostas antigas quando o filtro muda no meio de uma carga.
  int _generation = 0;

  ProductQuery get _firstPage => ProductQuery(
    gender: gender,
    categoryId: selectedCategory.value?.id,
    sort: sort.value,
    limit: pageSize,
  );

  List<Product> get products => switch (state.value) {
    UiSuccess(:final data) => data,
    _ => const [],
  };

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadCategories());
    unawaited(refreshProducts());
  }

  Future<void> _loadCategories() async {
    final result = await getCategories(gender);
    result.fold(categories.assignAll, (_) {}); // filtro é opcional
  }

  Future<void> refreshProducts() async {
    final generation = ++_generation;
    state.value = const UiLoading();
    final query = _firstPage;
    final result = await getProducts(query);
    if (generation != _generation) return;

    result.fold(
      (items) => _hasMore = items.length >= query.limit,
      (_) => _hasMore = false,
    );
    state.value = UiState.fromResult(result, isEmpty: (items) => items.isEmpty);
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !_hasMore || state.value is! UiSuccess) return;
    final generation = _generation;
    isLoadingMore.value = true;

    final current = products;
    final query = ProductQuery(
      gender: gender,
      categoryId: selectedCategory.value?.id,
      sort: sort.value,
      offset: current.length,
      limit: pageSize,
    );
    final result = await getProducts(query);
    isLoadingMore.value = false;
    if (generation != _generation) return;

    result.fold((items) {
      _hasMore = items.length >= query.limit;
      state.value = UiSuccess([...current, ...items]);
    }, (_) => _hasMore = false);
  }

  Future<void> selectCategory(Category? category) async {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    await refreshProducts();
  }

  Future<void> changeSort(ProductSort value) async {
    if (sort.value == value) return;
    sort.value = value;
    await refreshProducts();
  }
}
