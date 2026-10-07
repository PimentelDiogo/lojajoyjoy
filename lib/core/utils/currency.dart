import 'package:intl/intl.dart';

/// Formatação de moeda em Real: `R$ 189,90`.
abstract final class Currency {
  static final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  static String format(num value) => _brl.format(value);

  /// Valor sem símbolo para um campo de texto: `189,90`.
  static String formatInput(num value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');

  /// Lê o que a Ana digitou: `189,90`, `1.299,90`, `R$ 59`, `59.9`.
  /// Null se não for um valor válido com até 2 casas.
  static num? parse(String? text) {
    // Remove "R$", espaços e o espaço não separável (U+00A0) do intl.
    var value = (text ?? '').replaceAll(RegExp(r'[R$\s ]'), '');
    if (value.isEmpty) return null;
    if (value.contains(',')) {
      // Formato brasileiro: ponto = milhar, vírgula = decimal.
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (!RegExp(r'^\d+\.\d{1,2}$').hasMatch(value)) {
      // Sem vírgula: "1.299" = mil duzentos e noventa e nove.
      value = value.replaceAll('.', '');
    }
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) return null;
    return num.parse(value);
  }
}
