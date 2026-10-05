# ADR-0010 — Classe única de responsividade `AppResponsive`

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

O site precisa funcionar bem do **celular (maioria, via Instagram) ao desktop**. Requisito:
**uma classe de responsividade chamada em todas as telas**, evitando `MediaQuery` e
números mágicos espalhados.

## Decisão

Criar `core/responsive/app_responsive.dart` com:

1. **`AppResponsive`** — fonte única de breakpoints e valores adaptativos.
2. **Extension `context.responsive`** — atalho de uso.
3. **`ResponsivePage`** — widget "casca" que **toda tela** usa: centraliza o conteúdo, aplica
   largura máxima e padding conforme o dispositivo.

### Breakpoints

| Dispositivo | Largura | Colunas no grid | Padding | Navegação |
|---|---|---|---|---|
| `mobile` | `< 600` | 2 | 16 | AppBar + bottom/carrinho flutuante |
| `tablet` | `600 – 1023` | 3 | 24 | AppBar |
| `desktop` | `≥ 1024` | 4 (5 em ≥ 1440) | 32 | Header horizontal, conteúdo máx. 1280 |

### Contrato (esboço)

```dart
enum DeviceType { mobile, tablet, desktop }

class AppResponsive {
  const AppResponsive._(this.width);
  final double width;

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
  static const double wideBreakpoint = 1440;
  static const double maxContentWidth = 1280;

  factory AppResponsive.of(BuildContext context) =>
      AppResponsive._(MediaQuery.sizeOf(context).width);

  DeviceType get device => width >= desktopBreakpoint
      ? DeviceType.desktop
      : width >= tabletBreakpoint
          ? DeviceType.tablet
          : DeviceType.mobile;

  bool get isMobile => device == DeviceType.mobile;
  bool get isTablet => device == DeviceType.tablet;
  bool get isDesktop => device == DeviceType.desktop;

  /// Escolhe um valor por dispositivo; tablet/desktop herdam do menor se omitidos.
  T value<T>({required T mobile, T? tablet, T? desktop}) => switch (device) {
        DeviceType.mobile => mobile,
        DeviceType.tablet => tablet ?? mobile,
        DeviceType.desktop => desktop ?? tablet ?? mobile,
      };

  int get gridColumns => width >= wideBreakpoint ? 5 : value(mobile: 2, tablet: 3, desktop: 4);
  double get pagePadding => value(mobile: 16, tablet: 24, desktop: 32);
  double get gridSpacing => value(mobile: 12, tablet: 16, desktop: 24);
  double scaleFont(double base) => base * value(mobile: 1.0, tablet: 1.05, desktop: 1.1);
}

extension AppResponsiveX on BuildContext {
  AppResponsive get responsive => AppResponsive.of(this);
}
```

### Uso em todas as telas

```dart
class CatalogView extends GetView<CatalogController> {
  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return ResponsivePage(               // casca obrigatória
      child: Obx(() => GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: r.gridColumns,
          mainAxisSpacing: r.gridSpacing,
          crossAxisSpacing: r.gridSpacing,
          childAspectRatio: 0.62,
        ),
        itemCount: controller.products.length,
        itemBuilder: (_, i) => ProductCard(product: controller.products[i]),
      )),
    );
  }
}
```

### Regras

- **Proibido** `MediaQuery.of(context).size` direto em telas — sempre `context.responsive`.
- Layouts muito diferentes por dispositivo: usar `r.value(mobile: A(), desktop: B())` ou
  `ResponsiveBuilder(mobile:…, desktop:…)` — nunca `if (width > 712)` solto.
- Testes de widget de cada tela rodam em **3 tamanhos**: 390×844, 820×1180, 1440×900.

## Consequências

- **+** Breakpoints mudam em um só lugar; telas consistentes; fácil de testar.
- **−** Usa a largura da janela, não do pai. Para componentes que vivem em colunas
  (ex.: card no grid), usar `LayoutBuilder` local — exceção documentada.
