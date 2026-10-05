import 'package:flutter/widgets.dart';

enum DeviceType { mobile, tablet, desktop }

/// Fonte única de breakpoints e valores adaptativos (ADR-0010).
///
/// Uso obrigatório em todas as telas: `final r = context.responsive;`.
/// Proibido `MediaQuery.of(context).size` direto nas telas.
@immutable
final class AppResponsive {
  const AppResponsive(this.width);

  factory AppResponsive.of(BuildContext context) =>
      AppResponsive(MediaQuery.sizeOf(context).width);

  final double width;

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double wideBreakpoint = 1440;
  static const double maxContentWidth = 1280;

  DeviceType get device => width >= desktopBreakpoint
      ? DeviceType.desktop
      : width >= tabletBreakpoint
      ? DeviceType.tablet
      : DeviceType.mobile;

  bool get isMobile => device == DeviceType.mobile;
  bool get isTablet => device == DeviceType.tablet;
  bool get isDesktop => device == DeviceType.desktop;

  /// Escolhe um valor por dispositivo. Tablet e desktop herdam do tamanho
  /// menor quando omitidos.
  T value<T>({required T mobile, T? tablet, T? desktop}) => switch (device) {
    DeviceType.mobile => mobile,
    DeviceType.tablet => tablet ?? mobile,
    DeviceType.desktop => desktop ?? tablet ?? mobile,
  };

  /// Colunas do grid de produtos: 2 · 3 · 4 (5 em telas ≥ 1440).
  int get gridColumns =>
      width >= wideBreakpoint ? 5 : value(mobile: 2, tablet: 3, desktop: 4);

  double get pagePadding => value(mobile: 16, tablet: 24, desktop: 32);
  double get gridSpacing => value(mobile: 12, tablet: 16, desktop: 24);

  double scaleFont(double base) =>
      base * value(mobile: 1, tablet: 1.05, desktop: 1.1);

  @override
  bool operator ==(Object other) =>
      other is AppResponsive && other.width == width;

  @override
  int get hashCode => width.hashCode;
}

extension AppResponsiveX on BuildContext {
  AppResponsive get responsive => AppResponsive.of(this);
}
