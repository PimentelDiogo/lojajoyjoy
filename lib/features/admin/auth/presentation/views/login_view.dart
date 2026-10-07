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
            const SizedBox(height: AppSpacing.md),
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
