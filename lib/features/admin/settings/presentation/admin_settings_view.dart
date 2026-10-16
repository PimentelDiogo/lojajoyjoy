import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/admin_section_card.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/features/admin/settings/presentation/admin_settings_controller.dart';

/// Configurações da loja (ADR-0014: modo de auditoria de estoque).
class AdminSettingsView extends GetView<AdminSettingsController> {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
    final settings = controller.store.settings.value;
    if (settings == null) return const SizedBox.shrink();

    return AdminSectionCard(
      title: 'Modo de auditoria de estoque',
      subtitle: settings.inStockAudit
          ? null
          : 'Fecha a loja por um tempo enquanto você atualiza o estoque. '
                'O cliente vê a contagem regressiva na home.',
      child: settings.inStockAudit
          ? _Active(
              endsAt: settings.stockAuditEndsAt!,
              onStop: () => unawaited(_stop(context)),
              isSaving: controller.isSaving.value,
            )
          : _Idle(
              onStart: (minutes) => unawaited(_start(context, minutes)),
              isSaving: controller.isSaving.value,
            ),
    );
  });

  Future<void> _start(BuildContext context, int minutes) async {
    final failure = await controller.start(minutes);
    if (failure != null && context.mounted) {
      _showError(context, failure.message);
    }
  }

  Future<void> _stop(BuildContext context) async {
    final failure = await controller.stop();
    if (failure != null && context.mounted) {
      _showError(context, failure.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), persist: false));
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onStart, required this.isSaving});

  final ValueChanged<int> onStart;
  final bool isSaving;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final minutes in const [15, 30, 60])
        AppButton(
          label: minutes < 60 ? '$minutes min' : '1 hora',
          variant: AppButtonVariant.secondary,
          isLoading: isSaving,
          onPressed: isSaving ? null : () => onStart(minutes),
        ),
    ],
  );
}

class _Active extends StatefulWidget {
  const _Active({
    required this.endsAt,
    required this.onStop,
    required this.isSaving,
  });

  final DateTime endsAt;
  final VoidCallback onStop;
  final bool isSaving;

  @override
  State<_Active> createState() => _ActiveState();
}

class _ActiveState extends State<_Active> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.endsAt.difference(DateTime.now().toUtc());
    final local = widget.endsAt.toLocal();
    final hhmm =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            remaining.isNegative
                ? 'Em auditoria — previsto para $hhmm (a qualquer momento).'
                : 'Em auditoria — termina às $hhmm '
                      '(${_format(remaining)}).',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Reabrir a loja',
          icon: Icons.storefront_outlined,
          isLoading: widget.isSaving,
          onPressed: widget.isSaving ? null : widget.onStop,
        ),
      ],
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return minutes > 0 ? 'faltam ${minutes}min' : 'faltam ${seconds}s';
  }
}
