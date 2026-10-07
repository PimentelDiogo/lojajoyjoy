import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/state/ui_state.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/core/widgets/loading_skeleton.dart';
import 'package:joyjoy/features/admin/dashboard/domain/dashboard.dart';
import 'package:joyjoy/features/admin/dashboard/presentation/dashboard_controller.dart';
import 'package:joyjoy/features/tracking/domain/traffic_source.dart';

/// Conteúdo do painel: números do dia a dia da loja.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Olá! 👋', style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text('Resumo da loja', style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Obx(
          () => switch (controller.state.value) {
            UiIdle() || UiLoading() => const LoadingSkeleton(
              width: double.infinity,
              height: 120,
              radius: AppRadius.lg,
            ),
            UiSuccess(:final data) => _Stats(stats: data),
            UiEmpty() => const SizedBox.shrink(),
            UiFailure(:final failure) => ErrorState.fromFailure(
              failure,
              onRetry: () => unawaited(controller.load()),
            ),
          },
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final cards = [
      _KpiCard(
        icon: Icons.receipt_long_outlined,
        label: 'Pedidos aguardando confirmação',
        value: '${stats.pendingOrders}',
        onTap: () => unawaited(Get.offAllNamed<void>(AppRoutes.adminOrders)),
      ),
      _KpiCard(
        icon: Icons.checkroom_outlined,
        label: 'Peças ativas na vitrine',
        value: '${stats.activeProducts}',
        onTap: () => unawaited(Get.offAllNamed<void>(AppRoutes.adminProducts)),
      ),

      _KpiCard(
        icon: Icons.people_outline,
        label: 'Visitas nos últimos 7 dias',
        value: '${stats.totalVisits}',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: r.value(mobile: 1, tablet: 3),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: r.gridSpacing,
          crossAxisSpacing: r.gridSpacing,
          childAspectRatio: r.value(mobile: 3.2, tablet: 1.6, desktop: 2.2),
          children: cards,
        ),
        const SizedBox(height: AppSpacing.lg),
        _VisitsBySource(stats: stats),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Abre a área correspondente (pedidos, peças).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      button: onTap != null,
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: scheme.primary, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(value, style: textTheme.headlineMedium),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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

/// De onde vieram as visitas (ADR-0007) — prévia do relatório completo.
class _VisitsBySource extends StatelessWidget {
  const _VisitsBySource({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final total = stats.totalVisits;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'De onde vêm as visitas (7 dias)',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (total == 0)
              Text(
                'Ainda sem visitas registradas. Use os links com ?src= na bio e no WhatsApp.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              for (final MapEntry(key: source, value: count)
                  in stats.visitsBySource.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Semantics(
                    label: '${TrafficSource.labelOf(source)}: $count visitas',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(
                            TrafficSource.labelOf(source),
                            style: textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: count / total,
                              minHeight: 10,
                              backgroundColor: scheme.surfaceContainerHigh,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
