import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/price_text.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/cart/presentation/controllers/cart_controller.dart';
import 'package:joyjoy/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// Carrinho (/carrinho). Celular: lista + barra fixa com o total.
/// Tablet/desktop: lista + resumo ao lado.
class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CartController>();
    final r = context.responsive;

    return Obx(() {
      final cart = controller.cart.value;
      final showBottomBar = r.isMobile && !cart.isEmpty;

      return ResponsivePage(
        appBar: const AppHeader(actions: [AppThemeToggle()]),
        bottomBar: showBottomBar ? _MobileCheckoutBar(cart: cart) : null,
        body: cart.isEmpty
            ? EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Seu carrinho está vazio',
                message: 'Escolha suas peças favoritas.',
                actionLabel: 'Ver peças',
                onAction: () =>
                    unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
              )
            : ResponsiveBuilder(
                mobile: (_) => _ItemsList(cart: cart, controller: controller),
                tablet: (_) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ItemsList(cart: cart, controller: controller),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: _Summary(cart: cart)),
                  ],
                ),
              ),
      );
    });
  }
}

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.cart, required this.controller});

  final Cart cart;
  final CartController controller;

  Future<void> _remove(BuildContext context, CartItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final removed = await controller.remove(item.variantId);
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.productName} removida do carrinho'),
          // "Desfazer" some sozinho no tempo padrão (4 s) — sem persist.
          persist: false,
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () =>
                unawaited(controller.undoRemove(removed.$1, removed.$2)),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Seu carrinho (${cart.totalQuantity} ${cart.totalQuantity == 1 ? 'peça' : 'peças'})',
            style: textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in cart.items) ...[
          CartItemTile(
            key: ValueKey(item.variantId),
            item: item,
            onQuantityChanged: (q) =>
                unawaited(controller.updateQuantity(item.variantId, q)),
            onNoteChanged: (note) =>
                unawaited(controller.updateNote(item.variantId, note)),
            onRemove: () => unawaited(_remove(context, item)),
            onOpenProduct: () => unawaited(
              Get.toNamed<void>(AppRoutes.productPath(item.productSlug)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Continuar comprando',
            icon: Icons.arrow_back,
            variant: AppButtonVariant.text,
            onPressed: () =>
                unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
          ),
        ),
      ],
    );
  }
}

/// Resumo com o total e o botão de finalizar (tablet/desktop).
class _Summary extends StatelessWidget {
  const _Summary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resumo', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            _TotalRow(cart: cart),
            const SizedBox(height: AppSpacing.xs),
            const _ShippingNote(),
            const SizedBox(height: AppSpacing.lg),
            const _CheckoutButton(),
          ],
        ),
      ),
    );
  }
}

/// Barra fixa no rodapé do celular.
class _MobileCheckoutBar extends StatelessWidget {
  const _MobileCheckoutBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalRow(cart: cart),
              const SizedBox(height: AppSpacing.sm),
              const _CheckoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Subtotal (${cart.totalQuantity} ${cart.totalQuantity == 1 ? 'peça' : 'peças'})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      PriceText(price: cart.subtotal, size: PriceTextSize.large),
    ],
  );
}

class _ShippingNote extends StatelessWidget {
  const _ShippingNote();

  @override
  Widget build(BuildContext context) => Text(
    'Entrega e pagamento você combina com a Ana no WhatsApp.',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Finalizar no WhatsApp: bloqueado com a loja fechada (A14).
/// Leva para /finalizar (feature `order`).
class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton();

  @override
  Widget build(BuildContext context) {
    final store = Get.find<StoreController>();
    final brand = context.appColors;
    return Obx(() {
      if (!store.isOpen) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: brand.peach,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            store.settings.value?.closedMessage?.trim().isNotEmpty ?? false
                ? store.settings.value!.closedMessage!
                : 'Loja temporariamente fechada. Os pedidos voltam em breve.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: brand.onPeach,
            ),
          ),
        );
      }
      return AppButton(
        label: 'Finalizar no WhatsApp',
        icon: Icons.chat_outlined,
        expand: true,
        onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.checkout)),
      );
    });
  }
}
