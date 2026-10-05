import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ondas_que_faltam/app/routes/app_routes.dart';

class NotFoundView extends StatelessWidget {
  const NotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Página não encontrada',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Get.offAllNamed<void>(AppRoutes.landing),
                child: const Text('Voltar para a loja'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
