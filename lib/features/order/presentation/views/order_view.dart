import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_cart_button.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/presentation/controllers/order_controller.dart';
import 'package:joyjoy/features/order/presentation/widgets/order_admin_panel.dart';
import 'package:joyjoy/features/order/presentation/widgets/order_status_chip.dart';
import 'package:joyjoy/features/order/presentation/widgets/order_summary.dart';

/// Página do pedido (/pedido/:code) — o link que vai na mensagem da Ana.
class OrderView extends GetView<OrderController> {
  const OrderView({required this.code, super.key});

  final String code;

  @override
  String? get tag => code;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      maxWidth: 720,
      appBar: const AppHeader(actions: [AppCartButton(), AppThemeToggle()]),
      body: Obx(
        () => switch (controller.state.value) {
          UiIdle() || UiLoading() => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(width: 220, height: 28),
              SizedBox(height: AppSpacing.md),
              LoadingSkeleton(
                width: double.infinity,
                height: 160,
                radius: AppRadius.lg,
              ),
            ],
          ),
          UiSuccess(:final data) => _OrderDetails(
            order: data,
            controller: controller,
          ),
          UiEmpty() => const SizedBox.shrink(),
          UiFailure(:final NotFoundFailure failure) => EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Pedido não encontrado',
            message: '${failure.message} Confira o código no link.',
            actionLabel: 'Voltar para a loja',
            onAction: () => unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
          ),
          UiFailure(:final failure) => ErrorState.fromFailure(
            failure,
            onRetry: () => unawaited(controller.load()),
          ),
        },
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order, required this.controller});

  final Order order;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final brand = context.appColors;
    final date = DateFormat(
      "dd/MM/yyyy 'às' HH:mm",
      'pt_BR',
    ).format(order.createdAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.justCreated) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: brand.mint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: brand.onMint),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pedido enviado! Agora é só mandar a mensagem no WhatsApp da Ana.',
                    style: textTheme.bodyMedium?.copyWith(color: brand.onMint),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  'Pedido #${order.code}',
                  style: textTheme.headlineSmall,
                ),
              ),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        Text(
          date,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in order.items)
                  SummaryLine(
                    title: '${item.quantity}× ${item.productName}',
                    subtitle: 'Tam ${item.size} · ${item.colorName}',
                    note: item.note,
                    amount: item.subtotal,
                  ),
                const Divider(height: AppSpacing.lg),
                TotalLine(total: order.total),
                if (order.deliveryMethod != null ||
                    order.paymentMethod != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  if (order.deliveryMethod != null)
                    Text(
                      'Entrega: ${order.deliveryMethod!.label}',
                      style: textTheme.bodyMedium,
                    ),
                  if (order.paymentMethod != null)
                    Text(
                      'Pagamento: ${order.paymentMethod!.label}',
                      style: textTheme.bodyMedium,
                    ),
                ],
              ],
            ),
          ),
        ),
        // Obx: o painel aparece quando a sessão da Ana é confirmada.
        Obx(
          () => controller.isAdmin.value
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: OrderAdminPanel(order: order, controller: controller),
                )
              : const SizedBox.shrink(),
        ),
        // Para a própria Ana o botão não faz sentido.
        Obx(
          () => controller.isAdmin.value
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: AppButton(
                    label: 'Falar com a Ana sobre este pedido',
                    icon: Icons.chat_outlined,
                    expand: true,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => unawaited(controller.talkToStore()),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Voltar para a loja',
          variant: AppButtonVariant.text,
          onPressed: () => unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
        ),
        Obx(
          () => controller.isAdmin.value
              ? const SizedBox.shrink()
              : Align(
                  child: TextButton.icon(
                    // Ana abre o link que a cliente mandou → entra → volta aqui.
                    onPressed: () => unawaited(
                      Get.toNamed<void>(
                        AppRoutes.adminLoginPath(
                          next: AppRoutes.orderPath(order.code),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Sou a Ana, entrar'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
