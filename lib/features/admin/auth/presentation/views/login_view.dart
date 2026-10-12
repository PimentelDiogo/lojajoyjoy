import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/login_controller.dart';

/// Login da Ana (/admin/login). Cadastro público não existe (ADR-0011).
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  Future<void> _forgot(BuildContext context) async {
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: controller.email,
        onSend: controller.sendPasswordReset,
      ),
    );
    if (message != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 6),
            persist: false,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ResponsivePage(
      maxWidth: 440,
      appBar: const AppHeader(),
      body: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: Text('Área da loja', style: textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Entre para cadastrar peças e confirmar pedidos.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.username,
              ],
              textInputAction: TextInputAction.next,
              autocorrect: false,
              onChanged: (v) => controller.email = v,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => TextField(
                obscureText: controller.obscurePassword.value,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onChanged: (v) => controller.password = v,
                onSubmitted: (_) => unawaited(controller.submit()),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    tooltip: controller.obscurePassword.value
                        ? 'Mostrar senha'
                        : 'Esconder senha',
                    onPressed: () => controller.obscurePassword.toggle(),
                    icon: Icon(
                      controller.obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(() {
              final error = controller.error.value;
              if (error == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  error,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              );
            }),
            Obx(
              () => AppButton(
                label: 'Entrar',
                icon: Icons.login,
                expand: true,
                isLoading: controller.isSubmitting.value,
                onPressed: () => unawaited(controller.submit()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Esqueci minha senha',
              variant: AppButtonVariant.text,
              onPressed: () => unawaited(_forgot(context)),
            ),
            AppButton(
              label: 'Voltar para a loja',
              variant: AppButtonVariant.text,
              onPressed: () =>
                  unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.onSend,
  });

  final String initialEmail;
  final Future<String> Function(String email) onSend;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    final message = await widget.onSend(_email.text);
    if (mounted) Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Esqueci minha senha'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enviaremos um link para você criar uma nova senha.'),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => unawaited(_send()),
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _sending ? null : () => unawaited(_send()),
        child: const Text('Enviar link'),
      ),
    ],
  );
}
