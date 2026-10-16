import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';
import 'package:joyjoy/core/services/link_launcher.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/utils/whatsapp_link.dart';
import 'package:joyjoy/features/store/presentation/controllers/store_controller.dart';

/// Botão flutuante "Falar com a vendedora" (A12). Some enquanto a
/// configuração da loja não carregou.
class WhatsAppFab extends StatelessWidget {
  const WhatsAppFab({super.key});

  static const message =
      'Olá! Vim pelo site da JOYJOY e quero tirar uma dúvida.';

  @override
  Widget build(BuildContext context) {
    final store = Get.find<StoreController>();
    final brand = context.appColors;
    final isMobile = context.responsive.isMobile;

    return Obx(() {
      final number = store.settings.value?.whatsappNumber;
      final uri = number == null
          ? null
          : WhatsAppLink.tryBuild(number, message: message);
      // Sem configuração (ou número inválido): o botão não aparece.
      if (uri == null) return const SizedBox.shrink();

      void onPressed() => unawaited(Get.find<LinkLauncher>().open(uri));

      const icon = Icon(Icons.chat_outlined);
      return isMobile
          ? FloatingActionButton(
              tooltip: 'Falar com a vendedora no WhatsApp',
              backgroundColor: brand.whatsapp,
              foregroundColor: brand.onWhatsapp,
              onPressed: onPressed,
              child: icon,
            )
          : FloatingActionButton.extended(
              tooltip: 'Falar com a vendedora no WhatsApp',
              backgroundColor: brand.whatsapp,
              foregroundColor: brand.onWhatsapp,
              onPressed: onPressed,
              icon: icon,
              label: const Text('Falar com a vendedora'),
            );
    });
  }
}

/// Recado da loja (A2) e aviso de loja fechada (A14), no topo da vitrine.
class StoreNotices extends StatefulWidget {
  const StoreNotices({super.key});

  @override
  State<StoreNotices> createState() => _StoreNoticesState();
}

class _StoreNoticesState extends State<StoreNotices> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<StoreController>();
    final scheme = Theme.of(context).colorScheme;
    final brand = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Obx(() {
      final settings = store.settings.value;
      if (settings == null) return const SizedBox.shrink();

      final notices = <Widget>[
        if (settings.inStockAudit)
          _Notice(
            key: const Key('store-stock-audit'),
            icon: Icons.inventory_2_outlined,
            background: brand.peach,
            foreground: brand.onPeach,
            child: _AuditCountdown(
              endsAt: settings.stockAuditEndsAt!,
              style: textTheme.bodyMedium?.copyWith(color: brand.onPeach),
            ),
          )
        else if (!settings.isOpen)
          _Notice(
            key: const Key('store-closed'),
            icon: Icons.schedule_outlined,
            background: brand.peach,
            foreground: brand.onPeach,
            child: Text(
              settings.closedMessage?.trim().isNotEmpty ?? false
                  ? settings.closedMessage!
                  : 'Loja temporariamente fechada. Você pode ver as peças, '
                        'mas os pedidos voltam em breve.',
              style: textTheme.bodyMedium?.copyWith(color: brand.onPeach),
            ),
          ),
        if (settings.hasAnnouncement)
          _Notice(
            key: const Key('store-announcement'),
            icon: Icons.campaign_outlined,
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
            // Compacto (máx. 2 linhas) para não empurrar os produtos (E8).
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                settings.announcement!,
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
      ];
      if (notices.isEmpty) return const SizedBox.shrink();

      return Column(
        children: [
          for (final notice in notices) ...[
            notice,
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    });
  }
}

/// Contagem regressiva ao vivo (ADR-0014): só existe (e só liga o Timer)
/// enquanto a loja está mesmo em auditoria — nas outras telas, nenhum timer
/// roda, então `pumpAndSettle` nos testes continua funcionando normal.
class _AuditCountdown extends StatefulWidget {
  const _AuditCountdown({required this.endsAt, this.style});

  final DateTime endsAt;
  final TextStyle? style;

  @override
  State<_AuditCountdown> createState() => _AuditCountdownState();
}

class _AuditCountdownState extends State<_AuditCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(_message(widget.endsAt), style: widget.style);

  /// "Atualizando o estoque. Voltamos às 14:32 (faltam 12min)."
  String _message(DateTime endsAt) {
    final remaining = endsAt.difference(DateTime.now().toUtc());
    final local = endsAt.toLocal();
    final hhmm =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    if (remaining.isNegative) {
      return 'Atualizando o estoque. Voltamos a qualquer momento.';
    }
    final minutes = remaining.inMinutes;
    final faltam = minutes > 0
        ? 'faltam ${minutes}min'
        : 'faltam ${remaining.inSeconds}s';
    return 'Atualizando o estoque. Voltamos às $hhmm ($faltam).';
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.child,
    super.key,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: foreground, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: child),
      ],
    ),
  );
}
