import 'package:flutter/material.dart';
import 'package:ondas_que_faltam/app/widgets/app_theme_toggle.dart';
import 'package:ondas_que_faltam/core/responsive/app_responsive.dart';
import 'package:ondas_que_faltam/core/responsive/responsive_page.dart';
import 'package:ondas_que_faltam/core/theme/app_colors.dart';
import 'package:ondas_que_faltam/core/theme/app_spacing.dart';
import 'package:ondas_que_faltam/core/theme/contrast.dart';
import 'package:ondas_que_faltam/core/widgets/app_button.dart';
import 'package:ondas_que_faltam/core/widgets/app_header.dart';
import 'package:ondas_que_faltam/core/widgets/app_logo.dart';
import 'package:ondas_que_faltam/core/widgets/feedback_states.dart';
import 'package:ondas_que_faltam/core/widgets/loading_skeleton.dart';
import 'package:ondas_que_faltam/core/widgets/price_text.dart';

/// Vitrine do design system (rota `/design`, **só em debug**).
///
/// Substitui o Figma: é aqui que validamos cores, contraste, botões,
/// preços e estados nos temas claro/escuro e nos 3 tamanhos de tela.
class DesignSystemView extends StatelessWidget {
  const DesignSystemView({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final scheme = Theme.of(context).colorScheme;
    final brand = context.appColors;

    return ResponsivePage(
      appBar: AppHeader(
        title: 'Design system',
        accentColor: scheme.primaryContainer,
        actions: const [AppThemeToggle()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            title: 'Responsivo',
            child: Text(
              '${r.device.name} · ${r.width.toStringAsFixed(0)}px · '
              '${r.gridColumns} colunas · padding ${r.pagePadding.toInt()}',
            ),
          ),
          _Section(
            title: 'Cores (contraste texto/fundo)',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _Swatch('primary', scheme.primary, scheme.onPrimary),
                _Swatch(
                  'primaryContainer · Feminino',
                  scheme.primaryContainer,
                  scheme.onPrimaryContainer,
                ),
                _Swatch('secondary', scheme.secondary, scheme.onSecondary),
                _Swatch(
                  'secondaryContainer · Masculino',
                  scheme.secondaryContainer,
                  scheme.onSecondaryContainer,
                ),
                _Swatch(
                  'tertiaryContainer · Em estoque',
                  scheme.tertiaryContainer,
                  scheme.onTertiaryContainer,
                ),
                _Swatch('lavender', brand.lavender, brand.onLavender),
                _Swatch('peach · Últimas unidades', brand.peach, brand.onPeach),
                _Swatch('error · Esgotado', scheme.error, scheme.onError),
                _Swatch('surface', scheme.surface, scheme.onSurface),
              ],
            ),
          ),
          const _Section(
            title: 'Logo',
            child: Wrap(
              spacing: AppSpacing.lg,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [AppLogo(), AppLogo(size: 72), AppLogo(size: 120)],
            ),
          ),
          _Section(
            title: 'Tipografia',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ondas que Faltam',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  'Vestido Midi Linho',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Tecido leve, caimento fluido. Perfeito para o verão de Recife.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Botões',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(label: 'Comprar', onPressed: () {}),
                AppButton(
                  label: 'Finalizar no WhatsApp',
                  icon: Icons.chat_outlined,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Secundário',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Voltar para a loja',
                  variant: AppButtonVariant.outline,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Texto',
                  variant: AppButtonVariant.text,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Carregando',
                  isLoading: true,
                  onPressed: () {},
                ),
                const AppButton(label: 'Desabilitado', onPressed: null),
              ],
            ),
          ),
          const _Section(
            title: 'Preço',
            child: Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                PriceText(price: 189.9),
                PriceText(price: 25, compareAtPrice: 49.99),
                PriceText(
                  price: 1249.5,
                  compareAtPrice: 1500,
                  size: PriceTextSize.large,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Estados',
            child: ResponsiveBuilder(
              mobile: (_) => const Column(children: _states),
              desktop: (_) => const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StatePreview(child: _emptyState)),
                  Expanded(child: _StatePreview(child: _errorState)),
                  Expanded(child: _StatePreview(child: _skeletons)),
                ],
              ),
            ),
          ),
          _Section(
            title: 'Grid (${r.gridColumns} colunas)',
            child: GridView.count(
              crossAxisCount: r.gridColumns,
              mainAxisSpacing: r.gridSpacing,
              crossAxisSpacing: r.gridSpacing,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.75,
              children: List.generate(
                r.gridColumns * 2,
                (i) => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LoadingSkeleton(
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        LoadingSkeleton(width: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _emptyState = EmptyState(
  title: 'Seu carrinho está vazio',
  message: 'Escolha suas peças favoritas.',
  icon: Icons.shopping_bag_outlined,
);
const _errorState = ErrorState(message: 'Sem conexão. Verifique sua internet.');
const _skeletons = Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    LoadingSkeleton(width: 160, height: 20),
    SizedBox(height: AppSpacing.xs),
    LoadingSkeleton(width: double.infinity),
    SizedBox(height: AppSpacing.xs),
    LoadingSkeleton(width: 120),
  ],
);
const _states = [
  _StatePreview(child: _emptyState),
  _StatePreview(child: _errorState),
  _StatePreview(child: _skeletons),
];

class _StatePreview extends StatelessWidget {
  const _StatePreview({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xs),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.background, this.foreground);
  final String name;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final ratio = contrastRatio(background, foreground);
    return Container(
      width: 168,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
          ),
          Text(
            '${ratio.toStringAsFixed(1)}:1 ${ratio >= 4.5 ? 'AA' : '✗'}',
            style: TextStyle(color: foreground),
          ),
        ],
      ),
    );
  }
}
