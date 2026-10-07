/// Formata o número wa.me (5581986323686) para exibição: (81) 98632-3686.
String formatBrazilPhone(String digits) {
  final local = digits.startsWith('55') && digits.length >= 12
      ? digits.substring(2)
      : digits;
  if (local.length == 11) {
    return '(${local.substring(0, 2)}) ${local.substring(2, 7)}-${local.substring(7)}';
  }
  if (local.length == 10) {
    return '(${local.substring(0, 2)}) ${local.substring(2, 6)}-${local.substring(6)}';
  }
  return digits;
}
