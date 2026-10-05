import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/theme/app_colors.dart';
import 'package:joyjoy/core/theme/app_theme.dart';
import 'package:joyjoy/core/theme/contrast.dart';

/// Garante o compromisso do ADR-0009: texto com contraste AA (≥ 4.5:1).
void main() {
  test('contrastRatio: preto/branco = 21 e cor com ela mesma = 1', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.pink, Colors.pink), closeTo(1, 0.001));
  });

  for (final (name, theme) in [
    ('claro', AppTheme.light),
    ('escuro', AppTheme.dark),
  ]) {
    group('tema $name', () {
      final s = theme.colorScheme;
      final brand = theme.extension<AppColors>()!;

      test('tem a extensão AppColors e Material 3', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.extension<AppColors>(), isNotNull);
      });

      final textPairs = <String, (Color, Color)>{
        'onPrimary/primary': (s.onPrimary, s.primary),
        'primary/surface (links)': (s.primary, s.surface),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onSecondary/secondary': (s.onSecondary, s.secondary),
        'onSecondaryContainer/secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'onTertiaryContainer/tertiaryContainer': (
          s.onTertiaryContainer,
          s.tertiaryContainer,
        ),
        'onError/error': (s.onError, s.error),
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface (texto secundário)': (
          s.onSurfaceVariant,
          s.surface,
        ),
        'onLavender/lavender': (brand.onLavender, brand.lavender),
        'onPeach/peach': (brand.onPeach, brand.peach),
        'onMint/mint': (brand.onMint, brand.mint),
      };

      for (final MapEntry(key: pair, value: colors) in textPairs.entries) {
        test('contraste AA: $pair', () {
          expect(
            contrastRatio(colors.$1, colors.$2),
            greaterThanOrEqualTo(4.5),
          );
        });
      }

      test(
        'laranja do logo (brand) ≥ 3:1 sobre o fundo (elemento gráfico)',
        () {
          expect(
            contrastRatio(brand.brand, s.surface),
            greaterThanOrEqualTo(3),
          );
        },
      );

      test('ícone do WhatsApp com contraste ≥ 3:1 (elemento gráfico)', () {
        expect(
          contrastRatio(brand.onWhatsapp, brand.whatsapp),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }

  test('brightness de cada tema', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
