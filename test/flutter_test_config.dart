import 'dart:async';

import 'package:joyjoy/core/theme/app_typography.dart';

/// Executado pelo `flutter test` antes de cada arquivo de teste.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Testes não têm rede: sem download de fontes do Google.
  AppTypography.useGoogleFonts = false;
  await testMain();
}
