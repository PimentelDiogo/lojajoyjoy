import 'dart:ui';

/// Converte `#RRGGBB` (cadastrado pela Ana) em [Color]. Null se inválido.
Color? colorFromHex(String? hex) {
  if (hex == null) return null;
  final match = RegExp(r'^#?([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}
