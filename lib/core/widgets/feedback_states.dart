import 'package:flutter/material.dart';
import 'package:joyjoy/core/errors/failure.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';

/// Lista vazia, busca sem resultado, carrinho vazio etc.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inventory_2_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _StateLayout(
    icon: icon,
    iconColor: Theme.of(context).colorScheme.primary,
    title: title,
    message: message,
    action: actionLabel != null && onAction != null
        ? AppButton(
            label: actionLabel!,
            onPressed: onAction,
            variant: AppButtonVariant.secondary,
          )
        : null,
  );
}

/// Erro com opção de tentar de novo.
class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.message,
    this.title = 'Ops! Algo deu errado',
    this.onRetry,
    super.key,
  });

  factory ErrorState.fromFailure(Failure failure, {VoidCallback? onRetry}) =>
      ErrorState(message: failure.message, onRetry: onRetry);

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StateLayout(
    icon: Icons.error_outline,
    iconColor: Theme.of(context).colorScheme.error,
    title: title,
    message: message,
    action: onRetry != null
        ? AppButton(
            label: 'Tentar novamente',
            onPressed: onRetry,
            variant: AppButtonVariant.outline,
            icon: Icons.refresh,
          )
        : null,
  );
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
