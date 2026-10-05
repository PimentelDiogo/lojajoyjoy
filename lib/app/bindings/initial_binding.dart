import 'package:get/get.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';
import 'package:joyjoy/features/cart/data/datasources/cart_local_datasource.dart';
import 'package:joyjoy/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:joyjoy/features/cart/domain/repositories/cart_repository.dart';
import 'package:joyjoy/features/cart/domain/usecases/cart_usecases.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';
import 'package:joyjoy/features/catalog/data/datasources/catalog_remote_datasource.dart';
import 'package:joyjoy/features/catalog/data/repositories/catalog_repositories_impl.dart';
import 'package:joyjoy/features/catalog/domain/repositories/catalog_repositories.dart';
import 'package:joyjoy/features/store/data/datasources/store_remote_datasource.dart';
import 'package:joyjoy/features/store/data/repositories/store_repository_impl.dart';
import 'package:joyjoy/features/store/domain/repositories/store_repository.dart';
import 'package:joyjoy/features/store/domain/usecases/get_store_settings.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dependências globais (composition root), vivas durante todo o app.
///
/// Executado no `main` **antes** do `runApp`, porque o `GetMaterialApp`
/// já precisa do `ThemeController` para montar o tema.
///
/// Próximos PRs registram aqui: `SourceTracker` (PR-07), `AuthController` (PR-08).
class InitialBinding extends Bindings {
  InitialBinding({
    required this.env,
    required this.store,
    required this.supabase,
  });

  final Env env;
  final KeyValueStore store;
  final SupabaseClient supabase;

  @override
  void dependencies() {
    Get
      ..put<Env>(env, permanent: true)
      ..put<KeyValueStore>(store, permanent: true)
      ..put<SupabaseClient>(supabase, permanent: true)
      ..put<LinkLauncher>(const UrlLauncherLinkLauncher(), permanent: true)
      ..put(ThemeController(store), permanent: true)
      // Loja (feature compartilhada: recado, WhatsApp, loja fechada).
      ..put<StoreRepository>(
        StoreRepositoryImpl(StoreRemoteDataSourceImpl(supabase)),
        permanent: true,
      )
      ..put(
        StoreController(getStoreSettings: GetStoreSettings(Get.find())),
        permanent: true,
      )
      // Catálogo: repositórios compartilhados por landing, grid e (PR-05) detalhe.
      ..put<CatalogRemoteDataSource>(
        CatalogRemoteDataSourceImpl(supabase),
        permanent: true,
      )
      ..put<ProductRepository>(
        ProductRepositoryImpl(Get.find()),
        permanent: true,
      )
      ..put<CategoryRepository>(
        CategoryRepositoryImpl(Get.find()),
        permanent: true,
      )
      // Carrinho (feature compartilhada: header, detalhe, /carrinho).
      ..put<CartRepository>(
        CartRepositoryImpl(CartLocalDataSourceImpl(store)),
        permanent: true,
      )
      ..put(
        CartController(
          loadCart: LoadCart(Get.find()),
          saveCart: SaveCart(Get.find()),
        ),
        permanent: true,
      );
  }
}
