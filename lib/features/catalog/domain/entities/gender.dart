/// Seção da loja. `unissex` aparece tanto no Feminino quanto no Masculino.
enum Gender {
  feminino('Feminino'),
  masculino('Masculino'),
  unissex('Unissex');

  const Gender(this.label);

  final String label;

  static Gender fromName(String value) => Gender.values.firstWhere(
    (g) => g.name == value,
    orElse: () => Gender.unissex,
  );
}
