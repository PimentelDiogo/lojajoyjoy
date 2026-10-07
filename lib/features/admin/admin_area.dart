/// Entrada da área admin — importada com `deferred as` em `AppPages`, para
/// que o cliente da loja não baixe este código (ADR-0001).
library;

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/widgets/controller_scope.dart';
import 'package:joyjoy/features/admin/dashboard/data/dashboard_repository_impl.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_controller.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_view.dart';
import 'package:joyjoy/features/admin/orders/data/admin_order_repository_impl.dart';
import 'package:joyjoy/features/admin/orders/domain/admin_orders.dart';
import 'package:joyjoy/features/admin/orders/presentation/admin_orders_controller.dart';
import 'package:joyjoy/features/admin/orders/presentation/admin_orders_view.dart';
import 'package:joyjoy/features/admin/products/data/admin_product_repository_impl.dart';
import 'package:joyjoy/features/admin/products/data/image_picker/image_picker.dart';
import 'package:joyjoy/features/admin/products/domain/admin_products.dart';
import 'package:joyjoy/features/admin/products/presentation/controllers/admin_products_controller.dart';
import 'package:joyjoy/features/admin/products/presentation/controllers/product_form_controller.dart';
import 'package:joyjoy/features/admin/products/presentation/views/admin_products_view.dart';
import 'package:joyjoy/features/admin/products/presentation/views/product_form_view.dart';
import 'package:joyjoy/features/admin/shell/admin_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Registra as dependências do admin (DI do GetX) na primeira abertura.
/// Nos testes os repositórios já vêm registrados com fakes.
void registerAdminDependencies() {
  if (!Get.isRegistered<DashboardRepository>()) {
    Get.lazyPut<DashboardRepository>(
      () => DashboardRepositoryImpl(Get.find<SupabaseClient>()),
      fenix: true,
    );
  }
  if (!Get.isRegistered<AdminProductRepository>()) {
    Get.lazyPut<AdminProductRepository>(
      () => AdminProductRepositoryImpl(Get.find<SupabaseClient>()),
      fenix: true,
    );
  }
  if (!Get.isRegistered<AdminOrderRepository>()) {
    Get.lazyPut<AdminOrderRepository>(
      () => AdminOrderRepositoryImpl(Get.find<SupabaseClient>()),
      fenix: true,
    );
  }
  if (!Get.isRegistered<ProductImagePicker>()) {
    Get.lazyPut<ProductImagePicker>(createProductImagePicker, fenix: true);
  }
}

/// Painel inicial (/admin).
Widget buildAdminHome() {
  registerAdminDependencies();
  return ControllerScope<DashboardController>(
    create: () => DashboardController(getAdminStats: GetAdminStats(Get.find())),
    child: const AdminShell(selected: 0, child: DashboardView()),
  );
}

/// Pedidos (/admin/pedidos).
Widget buildAdminOrders() {
  registerAdminDependencies();
  return ControllerScope<AdminOrdersController>(
    create: () => AdminOrdersController(
      listOrders: ListAdminOrders(Get.find<AdminOrderRepository>()),
    ),
    child: const AdminShell(selected: 1, child: AdminOrdersView()),
  );
}

/// Lista de peças (/admin/produtos).
Widget buildAdminProducts() {
  registerAdminDependencies();
  return ControllerScope<AdminProductsController>(
    create: () {
      final repository = Get.find<AdminProductRepository>();
      return AdminProductsController(
        listProducts: ListAdminProducts(repository),
        setProductActive: SetProductActive(repository),
      );
    },
    child: const AdminShell(selected: 2, child: AdminProductsView()),
  );
}

/// Formulário de peça: [id] null = nova (/admin/produtos/nova).
Widget buildAdminProductForm(String? id) {
  registerAdminDependencies();
  final tag = id ?? 'nova';
  return ControllerScope<ProductFormController>(
    key: ValueKey('product-form-$tag'),
    tag: tag,
    create: () {
      final repository = Get.find<AdminProductRepository>();
      return ProductFormController(
        productId: id,
        getProductDraft: GetProductDraft(repository),
        saveProduct: SaveProduct(repository),
        listCategories: ListAdminCategories(repository),
        createCategoryUseCase: CreateCategory(repository),
        imagePicker: Get.find(),
        newId: const Uuid().v4,
      );
    },
    child: AdminShell(selected: 2, child: ProductFormView(tag: tag)),
  );
}
