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
- Acento por seção: **Feminino = rosa**, **Masculino = azul** (usado em header/badges da seção).

### Paleta inicial

| Token | Light | Dark | Uso |
|---|---|---|---|
| `background` | `#FFF8F3` (creme) | `#1C1A22` | Fundo das páginas |
| `surface` | `#FFFFFF` | `#26232E` | Cards |
| `primary` | `#A94E72` | `#F4A7B9` | Botões, links (5.2:1 sobre branco / 9.1:1 no dark) |
| `primaryContainer` | `#F9D5DF` (rosa pastel) | `#5A2B3C` | Chips, destaque Feminino |
| `secondary` | `#3F6E99` | `#A7C7E7` | Ações secundárias |
| `secondaryContainer` | `#D6E6F5` (azul bebê) | `#23384D` | Destaque Masculino |
| `tertiaryContainer` | `#D4F0E2` (menta) | `#21413A` | Sucesso / "Em estoque" |
| `lavender` | `#E6D9F0` | `#3A3048` | Ilustrações, banners |
| `peach` | `#FFE5CC` | `#4A3626` | Avisos / "Últimas unidades" |
| `onBackground` | `#3D3A4B` | `#EDE7F0` | Texto principal |
| `error` | `#B3261E` | `#F2B8B5` | Erros / "Esgotado" |

- Tipografia: `google_fonts` — **Poppins** (títulos) + **Inter** (texto). Revisar com as referências.
- Raio padrão 16, espaçamentos múltiplos de 4 (`AppSpacing`).

## Consequências

- **+** Acessível desde o início; troca de tema sem tocar nas telas.
- **−** Sem Figma, o visual é validado direto no app a cada PR de tela. Ajustes ficam em `app_colors.dart`/`app_typography.dart`.
