import 'dart:math' as math;
import 'dart:ui';

/// Razão de contraste WCAG 2.1 entre duas cores (1.0 a 21.0).
///
/// AA exige ≥ 4.5 para texto normal e ≥ 3.0 para texto grande / ícones.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
