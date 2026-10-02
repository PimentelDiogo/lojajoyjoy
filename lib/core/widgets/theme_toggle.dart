import 'package:flutter/material.dart';

/// Botão de tema (Automático → Claro → Escuro). Puro: recebe o modo atual e
/// o callback — a ligação com o `ThemeController` fica em `app/widgets`.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({required this.mode, required this.onPressed, super.key});

  final ThemeMode mode;
  final VoidCallback onPressed;

  static String labelFor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Tema: automático',
    ThemeMode.light => 'Tema: claro',
    ThemeMode.dark => 'Tema: escuro',
  };

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };
    return IconButton(
      tooltip: labelFor(mode),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}
