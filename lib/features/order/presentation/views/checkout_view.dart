import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/features/order/domain/entities/order.dart';
import 'package:joyjoy/features/order/presentation/controllers/checkout_controller.dart';
import 'package:joyjoy/features/order/presentation/widgets/order_summary.dart';

/// Finalizar pedido (/finalizar): dados opcionais + resumo + enviar.
class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      appBar: const AppHeader(actions: [AppThemeToggle()]),
      body: Obx(() {
        final cart = controller.cart.cart.value;
        if (cart.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Seu carrinho está vazio',
            message: 'Escolha suas peças antes de finalizar.',
            actionLabel: 'Ver peças',
            onAction: () => unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
          );
        }
        final form = _CheckoutForm(controller: controller);
        final summary = _CartSummary(controller: controller);
        return ResponsiveBuilder(
          mobile: (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summary,
              const SizedBox(height: AppSpacing.lg),
              form,
            ],
          ),
          tablet: (_) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: form),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 2, child: summary),
            ],
          ),
        );
      }),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    final cart = controller.cart.cart.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Seu pedido', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            for (final item in cart.items)
              SummaryLine(
                title: '${item.quantity}× ${item.productName}',
                subtitle: 'Tam ${item.size} · ${item.colorName}',
                note: item.note,
                amount: item.subtotal,
              ),
            const Divider(height: AppSpacing.lg),
            TotalLine(total: cart.subtotal),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Valores confirmados pela loja ao enviar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  const _CheckoutForm({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Finalizar pedido', style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Tudo opcional — você combina os detalhes com a Ana no WhatsApp.',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          maxLength: CheckoutController.maxNameLength,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          onChanged: (value) => controller.customerName = value,
          decoration: const InputDecoration(
            labelText: 'Seu nome (opcional)',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Entrega', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final option in DeliveryMethod.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: controller.delivery.value == option,
                  onSelected: (selected) =>
                      controller.delivery.value = selected ? option : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Pagamento', style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final option in PaymentMethod.values)
                ChoiceChip(
                  label: Text(option.label),
                  selected: controller.payment.value == option,
                  onSelected: (selected) =>
                      controller.payment.value = selected ? option : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          maxLength: CheckoutController.maxNoteLength,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) => controller.customerNote = value,
          decoration: const InputDecoration(
            labelText: 'Observação para a Ana (opcional)',
            hintText: 'Ex.: posso retirar sábado?',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SubmitArea(controller: controller),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Voltar ao carrinho',
          icon: Icons.arrow_back,
          variant: AppButtonVariant.text,
          onPressed: () => unawaited(Get.offNamed<void>(AppRoutes.cart)),
        ),
      ],
    );
  }
}

class _SubmitArea extends StatelessWidget {
  const _SubmitArea({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final state = controller.state.value;
      final closed = !controller.store.isOpen;
      final problem = controller.problemItemName;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (closed)
            _Banner(
              background: brand.peach,
              foreground: brand.onPeach,
              text:
                  controller.store.settings.value?.closedMessage
                          ?.trim()
                          .isNotEmpty ??
                      false
                  ? controller.store.settings.value!.closedMessage!
                  : 'Loja temporariamente fechada. Os pedidos voltam em breve.',
            )
          else ...[
            if (state case UiFailure(:final failure))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _Banner(
                  background: scheme.errorContainer,
                  foreground: scheme.onErrorContainer,
                  text: problem == null
                      ? failure.message
                      : '${failure.message}\n$problem',
                ),
              ),
            AppButton(
              label: 'Enviar pedido pelo WhatsApp',
              icon: Icons.chat_outlined,
              expand: true,
              isLoading: controller.isSubmitting,
              onPressed: () => unawaited(controller.submit()),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Você vai para o WhatsApp da Ana com o pedido pronto para enviar.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.background,
    required this.foreground,
    required this.text,
  });

  final Color background;
  final Color foreground;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: foreground),
    ),
  );
}
