import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/presentation/controllers/order_controller.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';

/// Ações da Ana no link do pedido: confirmar a venda (baixa o estoque) ou
/// cancelar (devolve o estoque se já estava confirmado).
class OrderAdminPanel extends StatelessWidget {
  const OrderAdminPanel({
    required this.order,
    required this.controller,
    super.key,
  });

  final Order order;
  final OrderController controller;

  String _date(DateTime value) =>
      DateFormat("dd/MM 'às' HH:mm").format(value.toLocal());

  Future<void> _confirm(BuildContext context) async {
    final ok = await _ask(
      context,
      title: 'Confirmar a venda?',
      message: order.totalQuantity == 1
          ? 'O estoque da peça deste pedido será baixado.'
          : 'O estoque das ${order.totalQuantity} peças deste pedido será baixado.',
      action: 'Confirmar venda',
    );
    if (!ok || !context.mounted) return;
    final failure = await controller.confirm();
    if (context.mounted) {
      _snack(context, failure?.message ?? 'Venda confirmada. Estoque baixado.');
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final ok = await _ask(
      context,
      title: 'Cancelar o pedido?',
      message: order.status == OrderStatus.confirmed
          ? 'A venda já foi confirmada: o estoque das peças volta.'
          : 'O estoque não muda (o pedido ainda não tinha baixado nada).',
      action: 'Cancelar pedido',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final failure = await controller.cancel();
    if (context.mounted) {
      _snack(context, failure?.message ?? 'Pedido cancelado.');
    }
  }

  Future<bool> _ask(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), persist: false));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final source = order.source;
    final info = <String>[
      if (order.customerName != null) 'Cliente: ${order.customerName}',
      if (order.customerNote != null) 'Observação: ${order.customerNote}',
      if (source != null) 'Origem: ${TrafficSource.labelOf(source)}',
      if (order.confirmedAt != null)
        'Venda confirmada em ${_date(order.confirmedAt!)}',
      if (order.cancelledAt != null)
        'Cancelado em ${_date(order.cancelledAt!)}',
    ];

    return Card(
      semanticContainer: false,
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Obx(() {
          final acting = controller.acting.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.storefront_outlined, color: scheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Área da loja',
                        style: textTheme.titleMedium,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => unawaited(
                      Get.offAllNamed<void>(AppRoutes.adminOrders),
                    ),
                    child: const Text('Todos os pedidos'),
                  ),
                ],
              ),
              for (final line in info)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(line, style: textTheme.bodyMedium),
                ),
              if (order.canConfirm || order.canCancel)
                const SizedBox(height: AppSpacing.md),
              if (order.canConfirm) ...[
                AppButton(
                  label: 'Confirmar venda',
                  icon: Icons.check_circle_outline,
                  expand: true,
                  isLoading: acting == OrderAction.confirm,
                  onPressed: acting == null
                      ? () => unawaited(_confirm(context))
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    'Confirme quando a cliente pagar: o estoque é baixado.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (order.canCancel)
                AppButton(
                  label: 'Cancelar pedido',
                  icon: Icons.cancel_outlined,
                  expand: true,
                  variant: AppButtonVariant.outline,
                  isLoading: acting == OrderAction.cancel,
                  onPressed: acting == null
                      ? () => unawaited(_cancel(context))
                      : null,
                ),
            ],
          );
        }),
      ),
    );
  }
}
