import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/currency.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/core/widgets/product_image.dart';
import 'package:joyjoy/features/admin/products/domain/entities/product_draft.dart';
import 'package:joyjoy/features/admin/products/presentation/controllers/admin_products_controller.dart';

/// Lista de peças da Ana (/admin/produtos): busca, filtro e mostrar/ocultar.
class AdminProductsView extends GetView<AdminProductsController> {
  const AdminProductsView({super.key});

  void _newProduct() =>
      unawaited(Get.offAllNamed<void>(AppRoutes.adminProductNew));

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final textTheme = Theme.of(context).textTheme;

    final search = TextField(
      onChanged: (v) => controller.query.value = v,
      decoration: const InputDecoration(
        labelText: 'Buscar peça',
        prefixIcon: Icon(Icons.search),
      ),
    );
    final filter = Obx(
      () => SegmentedButton<ProductFilter>(
        segments: [
          for (final f in ProductFilter.values)
            ButtonSegment(value: f, label: Text(f.label)),
        ],
        selected: {controller.filter.value},
        showSelectedIcon: false,
        onSelectionChanged: (s) => controller.filter.value = s.first,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Peças', style: textTheme.headlineSmall),
              ),
            ),
            AppButton(
              label: 'Nova peça',
              icon: Icons.add,
              onPressed: _newProduct,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (r.isMobile) ...[
          search,
          const SizedBox(height: AppSpacing.sm),
          filter,
        ] else
          Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: AppSpacing.md),
              filter,
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        Obx(
          () => switch (controller.state.value) {
            UiIdle() || UiLoading() => Column(
              children: [
                for (var i = 0; i < 4; i++)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: LoadingSkeleton(
                      width: double.infinity,
                      height: 80,
                      radius: AppRadius.md,
                    ),
                  ),
              ],
            ),
            UiFailure(:final failure) => ErrorState.fromFailure(
              failure,
              onRetry: () => unawaited(controller.load()),
            ),
            UiEmpty() => EmptyState(
              icon: Icons.checkroom_outlined,
              title: 'Nenhuma peça ainda',
              message: 'Cadastre a primeira peça da loja.',
              actionLabel: 'Nova peça',
              onAction: _newProduct,
            ),
            // `visible` lê busca/filtro aqui dentro → o Obx reage a eles.
            UiSuccess() => _List(
              controller: controller,
              products: controller.visible,
              toggling: controller.toggling.toSet(),
            ),
          },
        ),
      ],
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.controller,
    required this.products,
    required this.toggling,
  });

  final AdminProductsController controller;
  final List<AdminProductSummary> products;
  final Set<String> toggling;

  Future<void> _toggle(BuildContext context, AdminProductSummary p) async {
    final failure = await controller.toggleActive(p);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), persist: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (products.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Nenhuma peça encontrada',
        message: 'Tente outro nome ou mude o filtro.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          products.length == 1 ? '1 peça' : '${products.length} peças',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final p in products)
          _ProductTile(
            key: ValueKey(p.id),
            product: p,
            busy: toggling.contains(p.id),
            onTap: () => unawaited(
              Get.offAllNamed<void>(AppRoutes.adminProductEditPath(p.id)),
            ),
            onToggle: () => unawaited(_toggle(context, p)),
          ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.busy,
    required this.onTap,
    required this.onToggle,
    super.key,
  });

  final AdminProductSummary product;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final p = product;
    final stockText = p.totalStock == 0
        ? 'Esgotada'
        : '${p.totalStock} em estoque';
    final details = [
      Currency.format(p.price),
      stockText,
      if (p.categoryName != null) p.categoryName!,
      p.gender.label,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      semanticContainer: false,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 56,
                  height: 72,
                  child: Opacity(
                    opacity: p.isActive ? 1 : 0.5,
                    child: ProductImage(url: p.coverImageUrl),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Editar ${p.name}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall,
                            ),
                          ),
                          if (p.isFeatured) ...[
                            const SizedBox(width: AppSpacing.xxs),
                            Tooltip(
                              message: 'Destaque',
                              child: Icon(
                                Icons.star,
                                size: 16,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: p.totalStock == 0
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      if (!p.isActive)
                        Text(
                          'Oculta da loja',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Semantics(
                label: p.isActive
                    ? '${p.name} aparece na loja'
                    : '${p.name} está oculta',
                child: Switch(
                  value: p.isActive,
                  onChanged: busy ? null : (_) => onToggle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
