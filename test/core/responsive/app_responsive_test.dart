import 'package:flutter_test/flutter_test.dart';
import 'package:ondas_que_faltam/core/responsive/app_responsive.dart';

void main() {
  group('AppResponsive.device — breakpoints exatos', () {
    final cases = <double, DeviceType>{
      360: DeviceType.mobile,
      599: DeviceType.mobile,
      600: DeviceType.tablet,
      1023: DeviceType.tablet,
      1024: DeviceType.desktop,
      1920: DeviceType.desktop,
    };
    for (final MapEntry(key: width, value: expected) in cases.entries) {
      test('${width.toInt()}px → ${expected.name}', () {
        expect(AppResponsive(width).device, expected);
      });
    }
  });

  group('value()', () {
    test('cada dispositivo pega o seu valor', () {
      int pick(double w) =>
          AppResponsive(w).value(mobile: 1, tablet: 2, desktop: 3);

      expect(pick(390), 1);
      expect(pick(820), 2);
      expect(pick(1440), 3);
    });

    test('desktop herda do tablet, e o tablet herda do mobile', () {
      expect(const AppResponsive(1440).value(mobile: 'm', tablet: 't'), 't');
      expect(const AppResponsive(820).value(mobile: 'm'), 'm');
      expect(const AppResponsive(1440).value(mobile: 'm'), 'm');
    });
  });

  test('grid: 2 · 3 · 4 · 5 colunas', () {
    expect(const AppResponsive(390).gridColumns, 2);
    expect(const AppResponsive(820).gridColumns, 3);
    expect(const AppResponsive(1280).gridColumns, 4);
    expect(const AppResponsive(1439).gridColumns, 4);
    expect(const AppResponsive(1440).gridColumns, 5);
  });

  test('padding e espaçamento crescem com a tela', () {
    expect(const AppResponsive(390).pagePadding, 16);
    expect(const AppResponsive(820).pagePadding, 24);
    expect(const AppResponsive(1440).pagePadding, 32);
    expect(const AppResponsive(390).gridSpacing, 12);
    expect(const AppResponsive(1440).gridSpacing, 24);
  });

  test('scaleFont aumenta só em tablet e desktop', () {
    expect(const AppResponsive(390).scaleFont(10), 10);
    expect(const AppResponsive(820).scaleFont(10), closeTo(10.5, 0.001));
    expect(const AppResponsive(1440).scaleFont(10), closeTo(11, 0.001));
  });
}
