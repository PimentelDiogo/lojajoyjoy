import 'package:get/get.dart';
import 'package:ondas_que_faltam/core/config/env.dart';

/// Dependências globais, vivas durante todo o app.
///
/// Próximos PRs registram aqui: `ThemeController` (PR-02), `SupabaseService` (PR-03),
/// `CartController` (PR-06), `SourceTracker` (PR-07), `AuthController` (PR-08).
class InitialBinding extends Bindings {
  InitialBinding({required this.env});

  final Env env;

  @override
  void dependencies() {
    Get.put<Env>(env, permanent: true);
  }
}
