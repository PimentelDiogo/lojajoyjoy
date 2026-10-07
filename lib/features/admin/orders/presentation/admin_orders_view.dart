import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/currency.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/features/admin/orders/domain/admin_orders.dart';
import 'package:joyjoy/features/admin/orders/presentation/admin_orders_controller.dart';
import 'package:joyjoy/features/order/presentation/widgets/order_status_chip.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';

/// Pedidos da loja (/admin/pedidos). Tocar abre o link do pedido, onde a
/// Ana confirma a venda ou cancela.
class AdminOrdersView extends GetView<AdminOrdersController> {
  const AdminOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Pedidos', style: textTheme.headlineSmall),
              ),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: () => unawaited(controller.load()),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Obx(() {
          final state = controller.state.value;
          final hasData = state is UiSuccess;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<OrderFilter>(
                  segments: [
                    for (final f in OrderFilter.values)
                      ButtonSegment(
                        value: f,
                        label: Text(
                          hasData
                              ? '${f.label} (${controller.countOf(f)})'
                              : f.label,
                        ),
                      ),
                  ],
                  selected: {controller.filter.value},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => controller.filter.value = s.first,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              switch (state) {
                UiIdle() || UiLoading() => Column(
                  children: [
                    for (var i = 0; i < 3; i++)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: LoadingSkeleton(
                          width: double.infinity,
                          height: 72,
                          radius: AppRadius.md,
                        ),
                      ),
                  ],
                ),
                UiFailure(:final failure) => ErrorState.fromFailure(
                  failure,
                  onRetry: () => unawaited(controller.load()),
                ),
                UiEmpty() => const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhum pedido ainda',
                  message:
                      'Quando uma cliente finalizar no WhatsApp, o pedido aparece aqui.',
                ),
                UiSuccess() => _List(orders: controller.visible),
              },
            ],
          );
        }),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.orders});

  final List<AdminOrderSummary> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nada por aqui',
        message: 'Nenhum pedido com esse status.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in orders) _OrderTile(key: ValueKey(o.code), order: o),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, super.key});

  final AdminOrderSummary order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final o = order;
    final date = DateFormat("dd/MM 'às' HH:mm").format(o.createdAt.toLocal());
    final details = [
      date,
      if (o.itemCount == 1) '1 peça' else '${o.itemCount} peças',
      if (o.source != null) TrafficSource.labelOf(o.source!),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(Get.toNamed<void>(AppRoutes.orderPath(o.code))),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('#${o.code}', style: textTheme.titleSmall),
                        OrderStatusChip(status: o.status),
                      ],
                    ),
                    if (o.customerName != null)
                      Text(
                        o.customerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium,
                      ),
                    Text(
                      details,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(Currency.format(o.total), style: textTheme.titleSmall),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
