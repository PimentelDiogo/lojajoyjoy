/// Entrada da área admin — importada com `deferred as` em `AppPages`, para
/// que o cliente da loja não baixe este código (ADR-0001).
library;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:joyjoy/features/admin/dashboard/data/dashboard_repository_impl.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_controller.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_view.dart';
import 'package:joyjoy/features/admin/shell/admin_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registra as dependências do admin (DI do GetX) na primeira abertura.
void registerAdminDependencies() {
  if (!Get.isRegistered<DashboardRepository>()) {
    Get.lazyPut<DashboardRepository>(
      () => DashboardRepositoryImpl(Get.find<SupabaseClient>()),
      fenix: true,
    );
  }
  Get.lazyPut(
    () => DashboardController(getAdminStats: GetAdminStats(Get.find())),
  );
}

/// Painel inicial (/admin).
Widget buildAdminHome() {
  registerAdminDependencies();
  return const AdminShell(selected: 0, child: DashboardView());
}
