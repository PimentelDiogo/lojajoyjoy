/// Monta links `https://wa.me/<número>?text=<mensagem>` (ADR-0005).
abstract final class WhatsAppLink {
  static final _number = RegExp(r'^[0-9]{12,13}$');

  /// [number] no formato wa.me (só dígitos, com DDI). A [message] é sempre
  /// codificada com `Uri.encodeComponent` — texto digitado pelo cliente não
  /// consegue injetar parâmetros nem trocar o destino do link.
  static Uri build(String number, {String? message}) {
    if (!isValidNumber(number)) {
      throw ArgumentError.value(number, 'number', 'Formato wa.me inválido');
    }
    final text = message?.trim();
    final query = (text == null || text.isEmpty)
        ? ''
        : '?text=${Uri.encodeComponent(text)}';
    return Uri.parse('https://wa.me/$number$query');
  }

  /// Igual a [build], mas devolve null se o número for inválido
  /// (ex.: configuração da loja salva errada) em vez de lançar erro.
  static Uri? tryBuild(String number, {String? message}) =>
      isValidNumber(number) ? build(number, message: message) : null;

  static bool isValidNumber(String number) => _number.hasMatch(number);
}
