import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/app/widgets/app_cart_button.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';
import 'package:joyjoy/features/catalog/domain/entities/product.dart';
import 'package:joyjoy/features/catalog/presentation/controllers/landing_controller.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/catalog_product_card.dart';
import 'package:joyjoy/features/catalog/presentation/widgets/product_grid.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';
import 'package:joyjoy/features/store/presentation/widgets/store_footer.dart';
import 'package:joyjoy/features/store/presentation/widgets/store_widgets.dart';

/// Página inicial: Casual / Fitness e destaques.
class LandingView extends GetView<LandingController> {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      appBar: const AppHeader(actions: [AppCartButton(), AppThemeToggle()]),
      floatingActionButton: const WhatsAppFab(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveBuilder(
            mobile: (_) => const Column(
              children: [
                _SectionBlock(
                  gender: Gender.feminino,
                  route: AppRoutes.casual,
                ),
                SizedBox(height: AppSpacing.sm),
                _SectionBlock(
                  gender: Gender.masculino,
                  route: AppRoutes.fitness,
                ),
              ],
            ),
            tablet: (_) => const Row(
              children: [
                Expanded(
                  child: _SectionBlock(
                    gender: Gender.feminino,
                    route: AppRoutes.casual,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SectionBlock(
                    gender: Gender.masculino,
                    route: AppRoutes.fitness,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Featured(controller: controller),
          const StoreFooter(),
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
      label: 'Ver ${gender.label.toLowerCase()}',
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

/// Grid vertical de destaques.
class _Featured extends StatelessWidget {
  const _Featured({required this.controller});

  final LandingController controller;

  @override
  Widget build(BuildContext context) {
    final threshold = Get.find<StoreController>().lowStockThreshold;

    return Obx(() {
      final state = controller.featured.value;
      final body = switch (state) {
        UiIdle() || UiLoading() => const ProductGridSkeleton(),
        UiSuccess(data: final List<Product> items) => ProductGrid(
          products: items,
          lowStockThreshold: threshold,
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
