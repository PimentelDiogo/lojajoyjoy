import 'package:get/get.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/landing_controller.dart';

class LandingBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut(
        () => GetFeaturedProducts(Get.find<ProductRepository>()),
        fenix: true,
      )
      ..lazyPut(() => LandingController(getFeaturedProducts: Get.find()));
  }
}
