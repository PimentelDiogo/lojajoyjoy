import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:joyjoy/app/routes/app_routes.dart';
import 'package:joyjoy/core/responsive/responsive_page.dart';
import 'package:joyjoy/core/widgets/app_header.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      appBar: const AppHeader(),
      body: EmptyState(
        icon: Icons.search_off_outlined,
        title: 'Página não encontrada',
        message: 'O link pode estar errado ou a página foi removida.',
        actionLabel: 'Voltar para a loja',
        onAction: () => unawaited(Get.offAllNamed<void>(AppRoutes.landing)),
      ),
    );
  }
}
