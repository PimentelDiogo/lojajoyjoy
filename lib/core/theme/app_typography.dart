import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia: **Poppins** em títulos, **Inter** no texto e
/// **Cormorant Garamond** (serifa espaçada, próxima ao logo) no nome da marca.
///
/// As fontes vêm **embutidas** em `assets/google_fonts/` (pesos usados, cortadas
/// para o alfabeto latino: ~370 KB no total). Nada é baixado do Google em tempo
/// de execução: mais rápido no navegador do Instagram e sem enviar o IP das
/// clientes para terceiros (LGPD). Para trocar/adicionar um peso, ver
/// `assets/google_fonts/README.md`.
abstract final class AppTypography {
  /// Desligado nos testes (`test/flutter_test_config.dart`): usa a fonte
  /// padrão do Flutter, sem carregar os arquivos.
  static bool useGoogleFonts = true;

  static const _licenses = {
    'Inter': 'assets/google_fonts/OFL-inter.txt',
    'Poppins': 'assets/google_fonts/OFL-poppins.txt',
    'Cormorant Garamond': 'assets/google_fonts/OFL-cormorantgaramond.txt',
  };

  /// Só fontes locais + licenças OFL na tela de licenças. Chamar no `main`.
  static void configure() {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final MapEntry(key: family, value: path) in _licenses.entries) {
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks([
          family,
        ], await rootBundle.loadString(path));
      });
    }
  }

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

  /// Carrega as fontes antes do primeiro frame (no `main`), para o texto não
  /// "pular" nem cortar em widgets que medem o texto uma vez (ex.: chips).
  /// Se algo falhar, desiste após [timeout] e segue com a fonte padrão.
  static Future<void> preload({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!useGoogleFonts) return;
    try {
      for (final weight in bundledWeights) {
        GoogleFonts.inter(fontWeight: weight);
        GoogleFonts.poppins(fontWeight: weight);
      }
      GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600);
      await GoogleFonts.pendingFonts().timeout(timeout);
    } on Object catch (_) {
      // Sem fonte da marca: o app funciona com a fonte padrão.
    }
  }

  /// Pesos embutidos de Inter e Poppins (Cormorant: só 600, no wordmark).
  /// Peso fora desta lista cai na fonte padrão — o teste
  /// `app_typography_test.dart` garante que os arquivos existem.
  static const List<FontWeight> bundledWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ];

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
