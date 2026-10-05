import 'package:flutter_test/flutter_test.dart';
import 'package:joyjoy/core/utils/currency.dart';

import '../../helpers/pump_app.dart';

void main() {
  test('formata em Real com vírgula e milhar com ponto', () {
    expect(Currency.format(189.9), brl('189,90'));
    expect(Currency.format(25), brl('25,00'));
    expect(Currency.format(1249.5), brl('1.249,50'));
    expect(Currency.format(0), brl('0,00'));
  });

  test('arredonda para 2 casas', () {
    expect(Currency.format(49.999), brl('50,00'));
  });
}
