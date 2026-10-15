/// Seção da loja. `unissex` aparece tanto em Casual quanto em Fitness.
enum Gender {
  /// Seção "Casual" (exibição) — valor no banco: 'feminino'.
  feminino('Casual'),

  /// Seção "Fitness" (exibição) — valor no banco: 'masculino'.
  masculino('Fitness'),

  unissex('Unissex');

  const Gender(this.label);

  final String label;

  static Gender fromName(String value) => Gender.values.firstWhere(
    (g) => g.name == value,
    orElse: () => Gender.unissex,
  );
}
