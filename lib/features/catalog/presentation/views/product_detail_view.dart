import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_cart_button.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/color_hex.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/core/widgets/option_selectors.dart';
import 'package:joyjoy/core/widgets/price_text.dart';
import 'package:joyjoy/core/widgets/quantity_stepper.dart';
import 'package:joyjoy/features/cart/domain/entities/cart.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_detail.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/product_gallery.dart';
import 'package:joyjoy/features/store/presentation/widgets/store_widgets.dart';

/// Página do produto (/produto/:slug).
class ProductDetailView extends GetView<ProductDetailController> {
  const ProductDetailView({required this.slug, super.key});

  final String slug;

  @override
  String? get tag => slug;

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      appBar: const AppHeader(actions: [AppCartButton(), AppThemeToggle()]),
      floatingActionButton: const WhatsAppFab(),
      body: Obx(
        () => switch (controller.state.value) {
          UiIdle() || UiLoading() => const _DetailSkeleton(),
          UiSuccess(:final data) => _DetailLayout(
            product: data,
            controller: controller,
          ),
          UiEmpty() => const SizedBox.shrink(),
          UiFailure(:final NotFoundFailure failure) => EmptyState(
            icon: Icons.search_off_outlined,
            title: 'Peça não encontrada',
            message: failure.message,
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

class _DetailLayout extends StatelessWidget {
  const _DetailLayout({required this.product, required this.controller});

  final ProductDetail product;
  final ProductDetailController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final info = _ProductInfo(product: product, controller: controller);

    return ResponsiveBuilder(
      mobile: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductGallery(imageUrls: product.imageUrls),
          const SizedBox(height: AppSpacing.lg),
          info,
          const SizedBox(height: AppSpacing.xxl), // espaço do FAB
        ],
      ),
      tablet: (_) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: ProductGallery(
              imageUrls: product.imageUrls,
              showThumbnails: true,
            ),
          ),
          SizedBox(width: r.value<double>(mobile: 16, tablet: 24, desktop: 48)),
          Expanded(flex: 4, child: info),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product, required this.controller});

  final ProductDetail product;
  final ProductDetailController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final color = controller.selectedColor.value;
      final size = controller.selectedSize.value;
      final quantity = controller.quantity.value;
      final variant = controller.selectedVariant;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(product.name, style: textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.xs),
          PriceText(
            price: controller.price,
            compareAtPrice: product.compareAtPrice,
            size: PriceTextSize.large,
          ),
          if (variant != null && variant.inStock && variant.stock <= 2) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              variant.stock == 1
                  ? 'Última unidade!'
                  : 'Últimas ${variant.stock} unidades',
              style: textTheme.labelLarge?.copyWith(color: scheme.primary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (product.colors.isNotEmpty) ...[
            _Label('Cor', value: color),
            ColorSelector(
              options: [
                for (final c in product.colors)
                  SelectorOption(
                    value: c.name,
                    swatch: colorFromHex(c.hex),
                    available: product.variantsOf(c.name).any((v) => v.inStock),
                  ),
              ],
              selected: color,
              onSelected: controller.selectColor,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (controller.sizesForSelectedColor.isNotEmpty) ...[
            _Label('Tamanho', value: size),
            SizeSelector(
              options: [
                for (final v in controller.sizesForSelectedColor)
                  SelectorOption(value: v.size, available: v.inStock),
              ],
              selected: size,
              onSelected: controller.selectSize,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (controller.isSelectionSoldOut || controller.isProductSoldOut)
            _SoldOutBox(controller: controller)
          else ...[
            Row(
              children: [
                QuantityStepper(
                  value: quantity,
                  max: controller.maxQuantity < 1 ? 1 : controller.maxQuantity,
                  onIncrement: controller.increment,
                  onDecrement: controller.decrement,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: size == null
                        ? 'Escolha o tamanho'
                        : 'Adicionar ao carrinho',
                    icon: Icons.shopping_bag_outlined,
                    expand: true,
                    onPressed: controller.canAddToCart
                        ? () => unawaited(_onAddToCart(context))
                        : null,
                  ),
                ),
              ],
            ),
          ],
          if (product.description?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Sobre a peça', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(product.description!, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Ver mais ${product.gender.label.toLowerCase()}',
            variant: AppButtonVariant.text,
            icon: Icons.arrow_back,
            onPressed: () => unawaited(
              Get.offNamed<void>(
                product.gender == Gender.masculino
                    ? AppRoutes.masculino
                    : AppRoutes.feminino,
              ),
            ),
          ),
        ],
      );
    });
  }

  Future<void> _onAddToCart(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await controller.addToCart();
    final message = switch (outcome) {
      AddToCartOutcome.added ||
      AddToCartOutcome.merged => 'Adicionado ao carrinho!',
      AddToCartOutcome.limited =>
        'Adicionado até o limite disponível dessa peça.',
      AddToCartOutcome.atLimit =>
        'Você já tem o máximo disponível dessa peça no carrinho.',
      AddToCartOutcome.unavailable => 'Essa combinação está esgotada.',
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          // Com ação, o SnackBar do Flutter fica até a pessoa tocar (persist).
          // Aqui some sozinho em 3 s.
          duration: snackBarDuration,
          persist: false,
          action: SnackBarAction(
            label: 'Ver carrinho',
            onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.cart)),
          ),
        ),
      );
  }
}

/// Tempo do aviso "Adicionado ao carrinho".
const snackBarDuration = Duration(seconds: 3);

class _SoldOutBox extends StatelessWidget {
  const _SoldOutBox({required this.controller});

  final ProductDetailController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.isProductSoldOut
                ? 'Peça esgotada'
                : 'Esgotado nessa combinação',
            style: textTheme.titleSmall?.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Quer que a Ana te avise quando chegar?',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Avise-me pelo WhatsApp',
            icon: Icons.notifications_active_outlined,
            variant: AppButtonVariant.outline,
            expand: true,
            onPressed: () => unawaited(controller.notifyMe()),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.title, {this.value});

  final String title;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text.rich(
        TextSpan(
          text: '$title: ',
          style: textTheme.labelLarge,
          children: [
            TextSpan(
              text: value ?? 'escolha',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ResponsiveBuilder(
    mobile: (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: LoadingSkeleton(radius: AppRadius.lg),
        ),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(width: 220, height: 24),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: 120, height: 20),
      ],
    ),
    tablet: (_) => const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: LoadingSkeleton(radius: AppRadius.lg),
          ),
        ),
        SizedBox(width: AppSpacing.xl),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LoadingSkeleton(width: 260, height: 28),
              SizedBox(height: AppSpacing.sm),
              LoadingSkeleton(width: 120, height: 22),
            ],
          ),
        ),
      ],
    ),
  );
}
