import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';

/// Bloco do formulário do admin: título, ajuda opcional e conteúdo.
class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.error,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Mensagem de validação da seção (fica em destaque no topo).
  final String? error;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      // Sem isso o Card junta a semântica dos filhos num nó só e os botões
      // (ex.: "Adicionar fotos") somem para o leitor de tela.
      semanticContainer: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: textTheme.titleMedium),
                  ),
                ),
                ?trailing,
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
