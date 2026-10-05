import 'package:intl/intl.dart';

/// Formatação de moeda em Real: `R$ 189,90`.
abstract final class Currency {
  static final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  static String format(num value) => _brl.format(value);
}
