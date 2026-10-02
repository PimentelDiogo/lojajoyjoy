import 'package:flutter/material.dart';

/// Tokens de cor da marca (ADR-0009). **Nenhuma cor hardcoded fora daqui.**
///
/// Regra de acessibilidade: pastéis vão em superfícies/containers; texto e
/// botões usam as variações escuras ("on"), com contraste ≥ 4.5:1.
abstract final class AppPalette {
  // ---------- Light ----------
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFA94E72),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF9D5DF), // rosa pastel — Feminino
    onPrimaryContainer: Color(0xFF5A2B3C),
    secondary: Color(0xFF3F6E99),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD6E6F5), // azul bebê — Masculino
    onSecondaryContainer: Color(0xFF23384D),
    tertiary: Color(0xFF2F6B55),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD4F0E2), // menta — "Em estoque"
    onTertiaryContainer: Color(0xFF1B4334),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFFF8F3), // creme — fundo das páginas
    onSurface: Color(0xFF3D3A4B),
    onSurfaceVariant: Color(0xFF6B6778),
    surfaceContainerLowest: Color(0xFFFFFFFF), // cards
    surfaceContainerLow: Color(0xFFFFF3EC),
    surfaceContainer: Color(0xFFFBEFE8),
    surfaceContainerHigh: Color(0xFFF6E9E2),
    surfaceContainerHighest: Color(0xFFF1E4DC),
    outline: Color(0xFF8E8A99),
    outlineVariant: Color(0xFFE3D8D3),
    inverseSurface: Color(0xFF322F3B),
    onInverseSurface: Color(0xFFF6EFF4),
    inversePrimary: Color(0xFFF4A7B9),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ---------- Dark ----------
  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFF4A7B9),
    onPrimary: Color(0xFF3A1626),
    primaryContainer: Color(0xFF5A2B3C),
    onPrimaryContainer: Color(0xFFFFD9E2),
    secondary: Color(0xFFA7C7E7),
    onSecondary: Color(0xFF0E2A42),
    secondaryContainer: Color(0xFF23384D),
    onSecondaryContainer: Color(0xFFD6E6F5),
    tertiary: Color(0xFFB5E5CF),
    onTertiary: Color(0xFF0F3326),
    tertiaryContainer: Color(0xFF21413A),
    onTertiaryContainer: Color(0xFFD4F0E2),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF1C1A22),
    onSurface: Color(0xFFEDE7F0),
    onSurfaceVariant: Color(0xFFB5AFBF),
    surfaceContainerLowest: Color(0xFF17151C),
    surfaceContainerLow: Color(0xFF211E28),
    surfaceContainer: Color(0xFF26232E), // cards
    surfaceContainerHigh: Color(0xFF2E2A37),
    surfaceContainerHighest: Color(0xFF363241),
    outline: Color(0xFF8A8494),
    outlineVariant: Color(0xFF45404F),
    inverseSurface: Color(0xFFEDE7F0),
    onInverseSurface: Color(0xFF322F3B),
    inversePrimary: Color(0xFFA94E72),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

/// Cores da marca que não existem no `ColorScheme` do Material 3.
///
/// Acesso: `context.appColors.lavender`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.lavender,
    required this.onLavender,
    required this.peach,
    required this.onPeach,
    required this.whatsapp,
    required this.onWhatsapp,
  });

  /// Banners e ilustrações.
  final Color lavender;
  final Color onLavender;

  /// Avisos e "Últimas unidades".
  final Color peach;
  final Color onPeach;

  /// Botão do WhatsApp. Tom escuro do verde da marca para o ícone branco
  /// ter contraste ≥ 3:1 (elemento gráfico grande).
  final Color whatsapp;
  final Color onWhatsapp;

  static const light = AppColors(
    lavender: Color(0xFFE6D9F0),
    onLavender: Color(0xFF3D3A4B),
    peach: Color(0xFFFFE5CC),
    onPeach: Color(0xFF5A3A1A),
    whatsapp: Color(0xFF128C7E),
    onWhatsapp: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    lavender: Color(0xFF3A3048),
    onLavender: Color(0xFFEDE7F0),
    peach: Color(0xFF4A3626),
    onPeach: Color(0xFFFFE5CC),
    whatsapp: Color(0xFF128C7E),
    onWhatsapp: Color(0xFFFFFFFF),
  );

  @override
  AppColors copyWith({
    Color? lavender,
    Color? onLavender,
    Color? peach,
    Color? onPeach,
    Color? whatsapp,
    Color? onWhatsapp,
  }) => AppColors(
    lavender: lavender ?? this.lavender,
    onLavender: onLavender ?? this.onLavender,
    peach: peach ?? this.peach,
    onPeach: onPeach ?? this.onPeach,
    whatsapp: whatsapp ?? this.whatsapp,
    onWhatsapp: onWhatsapp ?? this.onWhatsapp,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      lavender: Color.lerp(lavender, other.lavender, t)!,
      onLavender: Color.lerp(onLavender, other.onLavender, t)!,
      peach: Color.lerp(peach, other.peach, t)!,
      onPeach: Color.lerp(onPeach, other.onPeach, t)!,
      whatsapp: Color.lerp(whatsapp, other.whatsapp, t)!,
      onWhatsapp: Color.lerp(onWhatsapp, other.onWhatsapp, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
