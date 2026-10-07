import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/errors/result.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';

enum ProductFilter {
  all('Todas'),
  active('Na vitrine'),
  inactive('Ocultas');

  const ProductFilter(this.label);
  final String label;
}

/// Lista de peças do admin: busca local (sem acento) e ativar/ocultar.
class AdminProductsController extends GetxController {
  AdminProductsController({
    required this.listProducts,
    required this.setProductActive,
  });

  final ListAdminProducts listProducts;
  final SetProductActive setProductActive;

  final Rx<UiState<List<AdminProductSummary>>> state =
      Rx<UiState<List<AdminProductSummary>>>(const UiIdle());
  final RxString query = ''.obs;
  final Rx<ProductFilter> filter = ProductFilter.all.obs;

  /// Ids com troca de ativo em andamento (evita toque duplo).
  final RxSet<String> toggling = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = const UiLoading();
    state.value = UiState.fromResult(
      await listProducts(const NoParams()),
      isEmpty: (list) => list.isEmpty,
    );
  }

  List<AdminProductSummary> get all => switch (state.value) {
    UiSuccess(:final data) => data,
    _ => const [],
  };

  /// Peças visíveis com a busca e o filtro atuais.
  List<AdminProductSummary> get visible {
    final terms = normalize(query.value).split(' ').where((t) => t.isNotEmpty);
    return all.where((p) {
      final matchesFilter = switch (filter.value) {
        ProductFilter.all => true,
        ProductFilter.active => p.isActive,
        ProductFilter.inactive => !p.isActive,
      };
      if (!matchesFilter) return false;
      final haystack = normalize('${p.name} ${p.categoryName ?? ''}');
      return terms.every(haystack.contains);
    }).toList();
  }

  /// Muda na tela na hora; volta atrás se o servidor recusar.
  Future<Failure?> toggleActive(AdminProductSummary product) async {
    if (toggling.contains(product.id)) return null;
    final next = !product.isActive;
    toggling.add(product.id);
    _replace(product.copyWith(isActive: next));
    final result = await setProductActive((id: product.id, active: next));
    toggling.remove(product.id);
    if (result case Failed(:final failure)) {
      _replace(product);
      return failure;
    }
    return null;
  }

  void _replace(AdminProductSummary product) {
    state.value = UiSuccess([
      for (final p in all) p.id == product.id ? product : p,
    ]);
  }

  static const _accents = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', 'ñ': 'n',
  };

  /// "Calça Rosê" → "calca rose" (a busca ignora acento e maiúscula).
  static String normalize(String text) =>
      text.toLowerCase().split('').map((c) => _accents[c] ?? c).join().trim();
}
