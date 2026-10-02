import 'package:flutter/material.dart';
import 'package:joyjoy/core/theme/app_theme.dart';
import 'package:joyjoy/core/widgets/feedback_states.dart';

/// Mostrada quando o build foi feito sem `--dart-define-from-file`
/// (só acontece em desenvolvimento ou num deploy mal configurado).
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.missingKeys, super.key});

  final List<String> missingKeys;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: Scaffold(
      body: ErrorState(
        title: 'Configuração ausente',
        message:
            'Faltando: ${missingKeys.join(', ')}.\n'
            'Rode com --dart-define-from-file=env/local.json',
      ),
    ),
  );
}
