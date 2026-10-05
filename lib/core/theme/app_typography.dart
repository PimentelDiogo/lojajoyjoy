import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia: **Poppins** em títulos, **Inter** no texto e
/// **Cormorant Garamond** (serifa espaçada, próxima ao logo) no nome da marca.
abstract final class AppTypography {
  /// Desligado nos testes (`test/flutter_test_config.dart`), que não têm rede
  /// para baixar as fontes. Nesse caso usa a fonte padrão do Flutter.
  static bool useGoogleFonts = true;

  /// Estilo do nome "JOYJOY" (wordmark): serifa em caixa alta, bem espaçada.
  static TextStyle wordmark(TextStyle base) {
    final style = base.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: (base.fontSize ?? 22) * 0.32,
      height: 1,
    );
    return useGoogleFonts
        ? GoogleFonts.cormorantGaramond(textStyle: style)
        : style;
  }

  static TextTheme textTheme(TextTheme base) {
    if (!useGoogleFonts) return base;

    final body = GoogleFonts.interTextTheme(base);
    TextStyle? heading(TextStyle? style) =>
        style == null ? null : GoogleFonts.poppins(textStyle: style);

    return body.copyWith(
      displayLarge: heading(body.displayLarge),
      displayMedium: heading(body.displayMedium),
      displaySmall: heading(body.displaySmall),
      headlineLarge: heading(body.headlineLarge),
      headlineMedium: heading(body.headlineMedium),
      headlineSmall: heading(body.headlineSmall),
      titleLarge: heading(body.titleLarge),
    );
  }
}
