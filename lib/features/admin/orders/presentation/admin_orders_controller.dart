import 'dart:async';

import 'package:get/get.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/usecase/usecase.dart';
import 'package:joyjoy/features/admin/orders/domain/admin_orders.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';

/// Filtro da lista. Abre em "Aguardando": é o que a Ana precisa resolver.
enum OrderFilter {
  pending('Aguardando', OrderStatus.pending),
  confirmed('Confirmados', OrderStatus.confirmed),
  cancelled('Cancelados', OrderStatus.cancelled),
  all('Todos', null);

  const OrderFilter(this.label, this.status);
  final String label;
  final OrderStatus? status;
}

class AdminOrdersController extends GetxController {
  AdminOrdersController({required this.listOrders});

  final ListAdminOrders listOrders;

  final Rx<UiState<List<AdminOrderSummary>>> state =
      Rx<UiState<List<AdminOrderSummary>>>(const UiIdle());
  final Rx<OrderFilter> filter = OrderFilter.pending.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    state.value = const UiLoading();
    state.value = UiState.fromResult(
      await listOrders(const NoParams()),
      isEmpty: (list) => list.isEmpty,
    );
  }

  List<AdminOrderSummary> get _all => switch (state.value) {
    UiSuccess(:final data) => data,
    _ => const [],
  };

  List<AdminOrderSummary> get visible {
    final status = filter.value.status;
    return status == null
        ? _all
        : _all.where((o) => o.status == status).toList();
  }

  int countOf(OrderFilter f) => f.status == null
      ? _all.length
      : _all.where((o) => o.status == f.status).length;
}
