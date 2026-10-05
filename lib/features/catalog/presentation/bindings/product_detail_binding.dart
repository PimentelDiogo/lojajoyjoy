import 'package:get/get.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// O controller usa `tag` = slug: dá para abrir um produto a partir de outro
/// (ex.: "veja também") sem misturar estados.
class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    final slug = Get.parameters['slug'] ?? '';
    Get
      ..lazyPut(
        () => GetProductBySlug(Get.find<ProductRepository>()),
        fenix: true,
      )
      ..lazyPut(
        () => ProductDetailController(
          slug: slug,
          getProductBySlug: Get.find(),
          store: Get.find<StoreController>(),
          launcher: Get.find<LinkLauncher>(),
        ),
        tag: slug,
      );
  }
}
