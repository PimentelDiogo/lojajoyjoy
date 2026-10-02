import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/product_card.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/landing_controller.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/catalog_product_card.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/product_grid.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:joyjoy/features/store/presentation/widgets/store_widgets.dart';

/// Página inicial: recado da loja, Feminino / Masculino e destaques.
class LandingView extends GetView<LandingController> {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      appBar: const AppHeader(actions: [AppThemeToggle()]),
      floatingActionButton: const WhatsAppFab(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StoreNotices(),
          ResponsiveBuilder(
            mobile: (_) => const Column(
              children: [
                _SectionBlock(
                  gender: Gender.feminino,
                  route: AppRoutes.feminino,
                ),
                SizedBox(height: AppSpacing.sm),
                _SectionBlock(
                  gender: Gender.masculino,
                  route: AppRoutes.masculino,
                ),
              ],
            ),
            tablet: (_) => const Row(
              children: [
                Expanded(
                  child: _SectionBlock(
                    gender: Gender.feminino,
                    route: AppRoutes.feminino,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SectionBlock(
                    gender: Gender.masculino,
                    route: AppRoutes.masculino,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Featured(controller: controller),
          const SizedBox(height: AppSpacing.xxl), // espaço do FAB
        ],
      ),
    );
  }
}

/// Bloco grande de entrada da seção (Feminino rosa / Masculino azul).
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.gender, required this.route});

  final Gender gender;
  final String route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final r = context.responsive;
    final background = gender.sectionColor(scheme);
    final foreground = gender.onSectionColor(scheme);

    return Semantics(
      button: true,
      label: 'Ver moda ${gender.label.toLowerCase()}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => unawaited(Get.toNamed<void>(route)),
          child: SizedBox(
            height: r.value<double>(mobile: 160, tablet: 240, desktop: 300),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  bottom: -24,
                  child: Icon(
                    Icons.checkroom_outlined,
                    size: r.value<double>(mobile: 150, desktop: 240),
                    color: foreground.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(
                    r.value<double>(mobile: 20, desktop: 32),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        gender.label,
                        style:
                            (r.isMobile
                                    ? textTheme.headlineMedium
                                    : textTheme.displaySmall)
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Text(
                            'Ver peças',
                            style: textTheme.titleMedium?.copyWith(
                              color: foreground,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: foreground,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carrossel horizontal de destaques.
class _Featured extends StatelessWidget {
  const _Featured({required this.controller});

  final LandingController controller;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final cardWidth = r.value<double>(mobile: 168, tablet: 200, desktop: 232);
    final height = ProductCard.extentFor(cardWidth);
    final threshold = Get.find<StoreController>().lowStockThreshold;

    Widget carousel(int count, IndexedWidgetBuilder builder) => SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(width: r.gridSpacing),
        itemBuilder: (context, index) =>
            SizedBox(width: cardWidth, child: builder(context, index)),
      ),
    );

    return Obx(() {
      final state = controller.featured.value;
      final body = switch (state) {
        UiIdle() ||
        UiLoading() => carousel(4, (_, _) => const ProductCardSkeleton()),
        UiSuccess(data: final List<Product> items) => carousel(
          items.length,
          (_, i) => CatalogProductCard(
            product: items[i],
            lowStockThreshold: threshold,
          ),
        ),
        UiEmpty() => null, // sem destaques: a seção some
        UiFailure(:final failure) => ErrorState.fromFailure(
          failure,
          onRetry: () => unawaited(controller.loadFeatured()),
        ),
      };
      if (body == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Destaques',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      );
    });
  }
}
