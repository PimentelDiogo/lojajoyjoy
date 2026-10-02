import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';

enum AppButtonVariant {
  /// Ação principal (Comprar, Finalizar no WhatsApp).
  primary,

  /// Ação de apoio com fundo pastel.
  secondary,

  /// Ação neutra com borda (Voltar para a loja).
  outline,

  /// Ação discreta, só texto.
  text,
}

/// Botão padrão da loja. Durante [isLoading] fica desabilitado e mostra um
/// indicador, evitando clique duplo (ex.: criar o pedido duas vezes).
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Ocupa toda a largura disponível (ex.: botão fixo no rodapé do celular).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final child = isLoading
        ? Semantics(
            label: 'Carregando',
            child: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: callback,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: callback, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
