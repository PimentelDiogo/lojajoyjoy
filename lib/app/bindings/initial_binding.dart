import 'package:get/get.dart';
import 'package:joyjoy/core/config/env.dart';
import 'package:joyjoy/core/services/key_value_store.dart';
import 'package:joyjoy/core/theme/theme_controller.dart';

/// Dependências globais, vivas durante todo o app.
///
/// Executado no `main` **antes** do `runApp`, porque o `GetMaterialApp`
/// já precisa do `ThemeController` para montar o tema.
///
/// Próximos PRs registram aqui: `SupabaseService` (PR-03),
/// `CartController` (PR-06), `SourceTracker` (PR-07), `AuthController` (PR-08).
class InitialBinding extends Bindings {
  InitialBinding({required this.env, required this.store});

  final Env env;
  final KeyValueStore store;

  @override
  void dependencies() {
    Get
      ..put<Env>(env, permanent: true)
      ..put<KeyValueStore>(store, permanent: true)
      ..put(ThemeController(store), permanent: true);
  }
}
