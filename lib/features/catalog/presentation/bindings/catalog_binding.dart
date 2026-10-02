import 'package:get/get.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';
import 'package:joyjoy/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/catalog_controller.dart';

/// Um binding por seção. O controller usa `tag` = gênero para que
/// /feminino e /masculino possam coexistir na pilha de navegação.
class CatalogBinding extends Bindings {
  CatalogBinding(this.gender);

  final Gender gender;

  @override
  void dependencies() {
    Get
      ..lazyPut(() => GetProducts(Get.find<ProductRepository>()), fenix: true)
      ..lazyPut(
        () => GetCategories(Get.find<CategoryRepository>()),
        fenix: true,
      )
      ..lazyPut(
        () => CatalogController(
          gender: gender,
          getProducts: Get.find(),
          getCategories: Get.find(),
        ),
        tag: gender.name,
      );
  }
}
