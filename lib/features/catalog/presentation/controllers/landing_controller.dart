import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';

class LandingController extends GetxController {
  LandingController({required this.getFeaturedProducts});

  final GetFeaturedProducts getFeaturedProducts;

  final Rx<UiState<List<Product>>> featured = Rx<UiState<List<Product>>>(
    const UiIdle(),
  );

  @override
  void onInit() {
    super.onInit();
    unawaited(loadFeatured());
  }

  Future<void> loadFeatured() async {
    featured.value = const UiLoading();
    final result = await getFeaturedProducts(const NoParams());
    featured.value = UiState.fromResult(
      result,
      isEmpty: (items) => items.isEmpty,
    );
  }
}
