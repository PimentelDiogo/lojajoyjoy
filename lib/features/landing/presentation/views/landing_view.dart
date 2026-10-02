import 'package:flutter/material.dart';
import 'package:joyjoy/app/widgets/app_theme_toggle.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';

/// Placeholder da landing. A versão real (Feminino / Masculino) chega no PR-04.
class LandingView extends StatelessWidget {
  const LandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsivePage(
      appBar: AppHeader(actions: [AppThemeToggle()]),
      body: EmptyState(
        icon: Icons.checkroom_outlined,
        title: 'Vitrine em construção',
        message: 'Em breve: moda feminina e masculina.',
      ),
    );
  }
}
