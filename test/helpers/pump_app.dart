import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:joyjoy/core/theme/app_theme.dart';

/// Valor em Real como o `intl` formata (espaço não separável U+00A0).
String brl(String value) => 'R\$\u00A0$value';

/// Tamanhos de referência (ADR-0010): celular, tablet e desktop.
const testViewports = <String, Size>{
  'mobile 390': Size(390, 844),
  'tablet 820': Size(820, 1180),
  'desktop 1440': Size(1440, 900),
};

extension PumpApp on WidgetTester {
  /// Define o tamanho da janela (em pixels lógicos) até o fim do teste.
  void setViewport(Size size) {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
  }

  /// Monta [child] dentro do tema da loja, no tamanho [size].
  ///
  /// Overflow de layout (RenderFlex) faz o teste falhar automaticamente —
  /// é assim que garantimos "nada fora da tela" em 390px.
  Future<void> pumpApp(
    Widget child, {
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    setViewport(size);
    await pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        // No app real toda tela tem Scaffold; aqui um Material dá o mesmo
        // contexto (ink, tema de texto) para widgets testados isoladamente.
        home: Material(type: MaterialType.transparency, child: child),
      ),
    );
    await pump();
  }
}
