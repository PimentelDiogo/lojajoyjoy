import 'package:flutter/material.dart';
import 'package:joyjoy/core/responsive/app_responsive.dart';

/// Casca obrigatória de **toda tela** (ADR-0010).
///
/// Centraliza o conteúdo, limita a largura máxima e aplica o padding do
/// dispositivo. Use `scrollable: false` quando o [body] já rola sozinho
/// (ex.: `GridView`, `ListView`).
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomBar,
    this.scrollable = true,
    this.maxWidth = AppResponsive.maxContentWidth,
    this.padding,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final bool scrollable;
  final double maxWidth;

  /// Sobrescreve o padding padrão do dispositivo.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.all(r.pagePadding),
          child: body,
        ),
      ),
    );

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}

/// Monta layouts diferentes por dispositivo sem `if (width > x)` solto.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    final builder = context.responsive.value(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    return builder(context);
  }
}
