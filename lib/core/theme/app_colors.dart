import 'package:flutter/material.dart';

/// Tokens de cor da marca (ADR-0009). **Nenhuma cor hardcoded fora daqui.**
///
/// Regra de acessibilidade: pastéis vão em superfícies/containers; texto e
/// botões usam as variações escuras ("on"), com contraste ≥ 4.5:1.
abstract final class AppPalette {
  // ---------- Light ----------
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB04E1C), // terracota (logo escurecido p/ AA)
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFBDCC8), // damasco pastel
    onPrimaryContainer: Color(0xFF5C2A0E),
    secondary: Color(0xFF3F6E99),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD6E6F5), // azul bebê — Masculino
    onSecondaryContainer: Color(0xFF23384D),
    tertiary: Color(0xFFA94E72),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF9D5DF), // rosa pastel — Feminino
    onTertiaryContainer: Color(0xFF5A2B3C),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFFCF3EA), // creme do logo — fundo das páginas
    onSurface: Color(0xFF3A2E28),
    onSurfaceVariant: Color(0xFF6E5F55),
    surfaceContainerLowest: Color(0xFFFFFFFF), // cards
    surfaceContainerLow: Color(0xFFFAEEE3),
    surfaceContainer: Color(0xFFF6E8DC),
    surfaceContainerHigh: Color(0xFFF1E2D5),
    surfaceContainerHighest: Color(0xFFECDCCD),
    outline: Color(0xFF9A8B80),
    outlineVariant: Color(0xFFE6D6C9),
    inverseSurface: Color(0xFF3A2E28),
    onInverseSurface: Color(0xFFFCF3EA),
    inversePrimary: Color(0xFFFFB38A),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // ---------- Dark (tons quentes) ----------
  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB38A),
    onPrimary: Color(0xFF4A1E05),
    primaryContainer: Color(0xFF6A2E10),
    onPrimaryContainer: Color(0xFFFFDBC9),
    secondary: Color(0xFFA7C7E7),
    onSecondary: Color(0xFF0E2A42),
    secondaryContainer: Color(0xFF23384D),
    onSecondaryContainer: Color(0xFFD6E6F5),
    tertiary: Color(0xFFF4A7B9),
    onTertiary: Color(0xFF3A1626),
    tertiaryContainer: Color(0xFF5A2B3C),
    onTertiaryContainer: Color(0xFFFFD9E2),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF1D1916),
    onSurface: Color(0xFFF2E9E3),
    onSurfaceVariant: Color(0xFFC2B5AB),
    surfaceContainerLowest: Color(0xFF171310),
    surfaceContainerLow: Color(0xFF211C18),
    surfaceContainer: Color(0xFF26211D), // cards
    surfaceContainerHigh: Color(0xFF2F2924),
    surfaceContainerHighest: Color(0xFF38312B),
    outline: Color(0xFF8F8279),
    outlineVariant: Color(0xFF4A413A),
    inverseSurface: Color(0xFFF2E9E3),
    onInverseSurface: Color(0xFF3A2E28),
    inversePrimary: Color(0xFFB04E1C),
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
    required this.brand,
    required this.mint,
    required this.onMint,
    required this.lavender,
    required this.onLavender,
    required this.peach,
    required this.onPeach,
    required this.whatsapp,
    required this.onWhatsapp,
  });

  /// Laranja exato do logo. Só para elementos gráficos (faixas, ícones,
  /// detalhes): contraste ~3:1 não serve para texto normal — use `primary`.
  final Color brand;

  /// "Em estoque" / sucesso.
  final Color mint;
  final Color onMint;

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
    brand: Color(0xFFE0662A),
    mint: Color(0xFFD4F0E2),
    onMint: Color(0xFF1B4334),
    lavender: Color(0xFFE6D9F0),
    onLavender: Color(0xFF3A2E28),
    peach: Color(0xFFFFE5CC),
    onPeach: Color(0xFF5A3A1A),
    whatsapp: Color(0xFF128C7E),
    onWhatsapp: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    brand: Color(0xFFE0662A),
    mint: Color(0xFF21413A),
    onMint: Color(0xFFD4F0E2),
    lavender: Color(0xFF3A3048),
    onLavender: Color(0xFFEDE7F0),
    peach: Color(0xFF4A3626),
    onPeach: Color(0xFFFFE5CC),
    whatsapp: Color(0xFF128C7E),
    onWhatsapp: Color(0xFFFFFFFF),
  );

  @override
  AppColors copyWith({
    Color? brand,
    Color? mint,
    Color? onMint,
    Color? lavender,
    Color? onLavender,
    Color? peach,
    Color? onPeach,
    Color? whatsapp,
    Color? onWhatsapp,
  }) => AppColors(
    brand: brand ?? this.brand,
    mint: mint ?? this.mint,
    onMint: onMint ?? this.onMint,
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
      brand: Color.lerp(brand, other.brand, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      onMint: Color.lerp(onMint, other.onMint, t)!,
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
