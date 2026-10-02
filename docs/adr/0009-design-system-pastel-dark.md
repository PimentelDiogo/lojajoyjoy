# ADR-0009 — Design system em tons pastéis com modo escuro

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

Identidade visual em **tons pastéis**, com opção de **modo noturno**. **Não haverá Figma**:
o design é construído em conjunto a partir de **lojas de referência** (`docs/design/referencias.md`).
Os tokens abaixo são o ponto de partida e evoluem conforme as validações de tela.

Problema clássico: **texto em cor pastel sobre fundo claro não passa no contraste WCAG AA**.

## Decisão

- **Material 3** (`useMaterial3: true`) com `ColorScheme` próprio para light e dark.
- Pastéis são usados em **superfícies, containers, chips, badges e ilustrações**; textos e
  botões usam as variações **"on"/escuras** para garantir contraste ≥ 4.5:1.
- Tokens centralizados em `core/theme/app_colors.dart` — **nenhuma cor hardcoded** em telas.
- `ThemeController` (GetX) com 3 modos: **Sistema (padrão) · Claro · Escuro**, persistido no `shared_preferences` (via `KeyValueStore`).
- Acento por seção: **Feminino = rosa** (`tertiaryContainer`), **Masculino = azul** (`secondaryContainer`). Faixa padrão do header = `brand`.

### Paleta (revisada em 2026-10-02 com o logo JOYJOY)

O logo é **creme `#FCF3EA` + laranja terracota `#E0662A`**. O terracota vira a cor principal,
e os pastéis seguem nos fundos e nas seções.

| Token | Light | Dark | Uso |
|---|---|---|---|
| `primary` | `#B04E1C` | `#FFB38A` | Botões, links, wordmark (5.3:1 / 10:1) |
| `brand` (AppColors) | `#E0662A` | `#E0662A` | Laranja exato do logo. **Só gráfico** (faixa do header, ícones): 3.1:1 não serve para texto |
| `primaryContainer` | `#FBDCC8` (damasco) | `#6A2E10` | Chips, destaques |
| `tertiaryContainer` | `#F9D5DF` (rosa pastel) | `#5A2B3C` | Seção **Feminino** |
| `secondaryContainer` | `#D6E6F5` (azul bebê) | `#23384D` | Seção **Masculino** |
| `mint` (AppColors) | `#D4F0E2` | `#21413A` | "Em estoque" |
| `peach` (AppColors) | `#FFE5CC` | `#4A3626` | "Últimas unidades" |
| `lavender` (AppColors) | `#E6D9F0` | `#3A3048` | Banners |
| `surface` | `#FCF3EA` (creme do logo) | `#1D1916` (escuro quente) | Fundo das páginas |
| `onSurface` | `#3A2E28` | `#F2E9E3` | Texto principal |
| `error` | `#B3261E` | `#F2B8B5` | Erros / "Esgotado" |

Todos os pares texto/fundo são verificados por teste automático (`app_theme_test.dart`, ≥ 4.5:1).

- Tipografia: `google_fonts` — **Poppins** (títulos) + **Inter** (texto) + **Cormorant Garamond** no wordmark "JOYJOY" (serifa espaçada, próxima ao logo).
- Raio padrão 16, espaçamentos múltiplos de 4 (`AppSpacing`).

## Consequências

- **+** Acessível desde o início; troca de tema sem tocar nas telas.
- **−** Sem Figma, o visual é validado direto no app a cada PR de tela. Ajustes ficam em `app_colors.dart`/`app_typography.dart`.
