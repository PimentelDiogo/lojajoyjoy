import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/theme/app_spacing.dart';
import 'package:joyjoy/core/widgets/app_button.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';
import 'package:joyjoy/features/admin/auth/domain/auth.dart';
import 'package:joyjoy/features/admin/auth/presentation/controllers/new_password_controller.dart';

/// Criar nova senha (link do e-mail "Esqueci minha senha").
class NewPasswordView extends GetView<NewPasswordController> {
  const NewPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (!controller.hasRecoverySession) {
      return ResponsivePage(
        maxWidth: 440,
        appBar: const AppHeader(),
        body: EmptyState(
          icon: Icons.link_off,
          title: 'Link inválido ou expirado',
          message:
              'Peça um novo link em "Esqueci minha senha" na tela de login.',
          actionLabel: 'Ir para o login',
          onAction: () =>
              unawaited(Get.offAllNamed<void>(AppRoutes.adminLogin)),
        ),
      );
    }

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
              child: Text('Criar nova senha', style: textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Pelo menos ${PasswordRules.minLength} caracteres, com letras e números.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Obx(
              () => TextField(
                obscureText: controller.obscure.value,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                onChanged: (v) => controller.password = v,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  suffixIcon: IconButton(
                    tooltip: controller.obscure.value
                        ? 'Mostrar senha'
                        : 'Esconder senha',
                    onPressed: controller.obscure.toggle,
                    icon: Icon(
                      controller.obscure.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Obx(
              () => TextField(
                obscureText: controller.obscure.value,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onChanged: (v) => controller.confirmation = v,
                onSubmitted: (_) => unawaited(controller.submit()),
                decoration: const InputDecoration(
                  labelText: 'Repita a nova senha',
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
                label: 'Salvar nova senha',
                icon: Icons.lock_reset,
                expand: true,
                isLoading: controller.isSubmitting.value,
                onPressed: () => unawaited(controller.submit()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
