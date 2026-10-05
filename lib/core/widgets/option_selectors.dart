import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';

/// Opção de um seletor (cor ou tamanho).
@immutable
class SelectorOption {
  const SelectorOption({
    required this.value,
    this.label,
    this.available = true,
    this.swatch,
  });

  final String value;

  /// Texto exibido (padrão: [value]).
  final String? label;

  /// Sem estoque: aparece riscada, mas continua clicável (para "Avise-me").
  final bool available;

  /// Cor da amostra (só no [ColorSelector]).
  final Color? swatch;

  String get text => label ?? value;
}

/// Amostras de cor redondas (referências A6).
class ColorSelector extends StatelessWidget {
  const ColorSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<SelectorOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          Semantics(
            button: true,
            selected: option.value == selected,
            label: 'Cor ${option.text}${option.available ? '' : ', esgotada'}',
            excludeSemantics: true,
            child: Tooltip(
              message: option.text,
              child: InkResponse(
                onTap: () => onSelected(option.value),
                radius: _size / 2 + 6,
                child: Container(
                  width: _size + 8,
                  height: _size + 8,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: option.value == selected
                          ? scheme.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: Opacity(
                    opacity: option.available ? 1 : 0.4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: option.swatch ?? scheme.surfaceContainerHigh,
                        border: Border.all(color: scheme.outline),
                      ),
                      child: option.swatch == null
                          ? Center(
                              child: Text(
                                option.text.characters.first.toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Botões de tamanho (PP, P, M… / 36, 38…).
class SizeSelector extends StatelessWidget {
  const SizeSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<SelectorOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final option in options)
          Semantics(
            button: true,
            selected: option.value == selected,
            label:
                'Tamanho ${option.text}${option.available ? '' : ', esgotado'}',
            excludeSemantics: true,
            child: _SizeButton(
              option: option,
              isSelected: option.value == selected,
              scheme: scheme,
              textStyle: textTheme.labelLarge,
              onTap: () => onSelected(option.value),
            ),
          ),
      ],
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.option,
    required this.isSelected,
    required this.scheme,
    required this.textStyle,
    required this.onTap,
  });

  final SelectorOption option;
  final bool isSelected;
  final ColorScheme scheme;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected
        ? scheme.onPrimary
        : option.available
        ? scheme.onSurface
        : scheme.onSurfaceVariant;

    return Material(
      color: isSelected ? scheme.primary : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: isSelected ? scheme.primary : scheme.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(
              widthFactor: 1,
              child: Text(
                option.text,
                style: textStyle?.copyWith(
                  color: foreground,
                  decoration: option.available
                      ? null
                      : TextDecoration.lineThrough,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
