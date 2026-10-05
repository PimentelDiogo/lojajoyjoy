import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/widgets/app_cart_button.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/features/catalog/domain/entities/category.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product_query.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/catalog_product_card.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/product_grid.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:joyjoy/features/store/presentation/widgets/store_widgets.dart';

/// Grid da seção (/feminino ou /masculino).
class CatalogView extends GetView<CatalogController> {
  const CatalogView({required this.gender, super.key});

  final Gender gender;

  @override
  String? get tag => gender.name;

  /// Começa a buscar a próxima página quando faltam ~600px para o fim.
  static const _loadMoreThreshold = 600.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = Get.find<StoreController>();
    final r = context.responsive;

    return ResponsivePage(
      scrollable: false,
      padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
      appBar: AppHeader(
        accentColor: gender.sectionColor(scheme),
        actions: const [AppCartButton(), AppThemeToggle()],
      ),
      floatingActionButton: const WhatsAppFab(),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < _loadMoreThreshold) {
            unawaited(controller.loadMore());
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: controller.refreshProducts,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: r.pagePadding)),
              const SliverToBoxAdapter(child: StoreNotices()),
              SliverToBoxAdapter(
                child: _Toolbar(gender: gender, controller: controller),
              ),
              SliverToBoxAdapter(child: _CategoryChips(controller: controller)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              Obx(
                () => switch (controller.state.value) {
                  UiIdle() || UiLoading() => const ProductSliverGridSkeleton(),
                  UiSuccess(:final data) => ProductSliverGrid(
                    products: data,
                    lowStockThreshold: store.lowStockThreshold,
                  ),
                  UiEmpty() => SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.checkroom_outlined,
                      title: 'Nenhuma peça por aqui ainda',
                      message: controller.selectedCategory.value == null
                          ? 'Novidades chegando em breve.'
                          : 'Tente outra categoria.',
                      actionLabel: controller.selectedCategory.value == null
                          ? null
                          : 'Ver todas',
                      onAction: () =>
                          unawaited(controller.selectCategory(null)),
                    ),
                  ),
                  UiFailure(:final failure) => SliverToBoxAdapter(
                    child: ErrorState.fromFailure(
                      failure,
                      onRetry: () => unawaited(controller.refreshProducts()),
                    ),
                  ),
                },
              ),
              SliverToBoxAdapter(
                child: Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: controller.isLoadingMore.value
                        ? const Center(child: CircularProgressIndicator())
                        : const SizedBox(
                            height: AppSpacing.xxl,
                          ), // espaço do FAB
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.gender, required this.controller});

  final Gender gender;
  final CatalogController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(gender.label, style: textTheme.headlineSmall),
            ),
          ),
          Obx(
            () => PopupMenuButton<ProductSort>(
              tooltip: 'Ordenar',
              initialValue: controller.sort.value,
              onSelected: (value) => unawaited(controller.changeSort(value)),
              itemBuilder: (_) => [
                for (final option in ProductSort.values)
                  PopupMenuItem(value: option, child: Text(option.label)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_vert, size: 20),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      controller.sort.value.label,
                      style: textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final CatalogController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    if (controller.categories.isEmpty) return const SizedBox.shrink();
    final selected = controller.selectedCategory.value;

    Widget chip(String label, Category? category) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: selected == category,
        onSelected: (_) => unawaited(controller.selectCategory(category)),
      ),
    );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip('Todas', null),
          for (final category in controller.categories)
            chip(category.name, category),
        ],
      ),
    );
  });
}
