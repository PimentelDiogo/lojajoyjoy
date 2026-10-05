# JOYJOY (lojajoyjoy) — Contexto

> Herda: global → `Projetos/CLAUDE.md` → este arquivo.

## Visão geral
Loja web de roupas **masculinas e femininas** da **Ana**. Link único (bio do Instagram,
WhatsApp, navegador). Landing → Feminino/Masculino → grid → carrinho → **pedido finalizado no
WhatsApp da Ana** com mensagem pronta. Admin da Ana: produtos (imagens, descrição, tamanhos,
cores), estoque, pedidos (baixa de estoque pelo link do pedido), relatórios de vendas e origem
dos clientes (Instagram × WhatsApp × site).

**Estágio:** PR-01 a PR-04 no GitHub. PR-05 (detalhe do produto) na branch `feat/pr-05-detalhe-produto`. Próximo: PR-06 (carrinho).

**WhatsApp da Ana:** +55 81 98632-3686 → `5581986323686` (fica em `store_settings`, não no código).

## Stack
- **Flutter Web** (Dart 3) — ADR-0001
- **Clean Architecture** organizada por feature — ADR-0004
- **GetX** para **gerência de estado, injeção de dependência e rotas** (`GetMaterialApp`, `GetMiddleware`) — ADR-0003
- **Supabase**: Postgres, RLS, RPCs plpgsql, Auth, Storage — ADR-0002
- Local: **Supabase CLI** (Postgres 17 em Docker), migrations em `supabase/migrations` — ADR-0008
- Hospedagem: Vercel **proposto, não decidido** — ADR-0012

## Arquitetura / padrões
- Fluxo: `View → Controller (GetX) → UseCase → Repository (contrato) ← RepositoryImpl → DataSource`.
- `domain` é Dart puro (sem Flutter/GetX/Supabase). GetX só em `presentation` e `bindings`.
- DI por `Binding` de rota (`Get.lazyPut`); serviços globais no `InitialBinding`.
- Erros como `Result<T>`/`Failure`; estado como `Rx<UiState<T>>`.
- **Responsividade:** toda tela usa `ResponsivePage` + `context.responsive` (`AppResponsive`).
  Proibido `MediaQuery...size` direto nas telas. Breakpoints: <600 mobile, 600–1023 tablet, ≥1024 desktop — ADR-0010.
- **Tema:** tons pastéis + modo escuro; cores só via tokens de `core/theme` — ADR-0009.
- **Reaproveitamento:** antes de criar widget, checar `core/widgets/`. Usado em 2+ features → sobe para `core/`.
- **Regras de negócio sensíveis no banco** (RPC `security definer` + RLS): `create_order`,
  `confirm_order` (baixa de estoque), `cancel_order`, `adjust_stock`, `track_visit`.
- Schema **só muda por migration**.
- **Features (PR-04):** `catalog` (landing + grid; a landing é a entrada do catálogo) e `store` (configuração
  da loja). **Exceção à regra "feature não importa feature":** `store` é compartilhada (como o tema) —
  qualquer feature pode usar `StoreController`, `WhatsAppFab` e `StoreNotices`. Repositórios globais
  (`ProductRepository`, `CategoryRepository`, `StoreRepository`) ficam no `InitialBinding`.
- Componentes novos (PR-05): `ColorSelector`/`SizeSelector` (`option_selectors.dart`; opção esgotada fica riscada mas clicável p/ "Avise-me"), `QuantityStepper`, `ProductImage` (foto + placeholder). `SizeOrder` ordena PP→GG→números.
- Controllers por rota com parâmetro usam `tag` = parâmetro (ex.: `ProductDetailController` tag = slug).
- Links externos só via `LinkLauncher` + `WhatsAppLink.build/tryBuild` (codifica o texto; valida o número).
- Fontes do Google são pré-carregadas no `main` (`AppTypography.preload`, timeout 3 s) — sem isso, chips
  cortavam o texto ao trocar de fonte.
- **Não teremos Figma.** O design é feito em conjunto, a partir de lojas de referência
  (screenshots via Playwright MCP) registradas em `docs/design/referencias.md`. Tokens no ADR-0009.

## Fluxo de PR (obrigatório)
- Branch `feat/pr-XX-nome` → testes → `flutter analyze` → **`/security-review` ao término de cada PR** → descrição (o que fez + impacto) → **pedir permissão** antes de abrir/mergear o PR.
- Definition of Done completo em `docs/plano/PLANO-EXECUCAO-MVP.md` §3.
- Flutter **3.44.9** fixado via **FVM** (`.fvmrc`) — sempre `fvm flutter ...` (o global é 3.19.6).
- Lint: `very_good_analysis`. `Result<T>` = `Success` | `Failed` (não usar `Error`, conflita com `dart:core`).
- **Rotas:** registrar toda página via `AppPages._page(...)` — aplica o `StrictRouteMiddleware` (o GetX casa
  rotas por prefixo e, sem isso, URL desconhecida abriria a landing em vez do 404).
- Admin local (seed, só dev): `ana@joyjoy.com.br`. Na nuvem usar outra senha forte.

## Design system (PR-02)
- **Marca JOYJOY:** cor principal terracota (`primary` `#B04E1C`); laranja exato do logo `#E0662A` = `appColors.brand`, **só para gráficos** (3.1:1). Fundo = creme do logo `#FCF3EA`. Feminino = `tertiaryContainer` (rosa), Masculino = `secondaryContainer` (azul).
- Header: `AppHeader()` sem `title` mostra o `AppWordmark` (Cormorant Garamond espaçada). `AppLogo` (círculo) fica para splash/ícones/`/design`.
- Tokens em `core/theme/` (`AppPalette`, `AppColors` via `context.appColors`, `AppSpacing`, `AppRadius`,
  `AppTypography`, `AppTheme.light/dark`). O teste `app_theme_test.dart` **reprova** par de cor abaixo de AA.
- Componentes puros em `core/widgets/`: `AppButton`, `PriceText`, `EmptyState`, `ErrorState`, `LoadingSkeleton`,
  `ThemeToggle`, `AppHeader`, `AppLogo`, `AppWordmark`. **Sem `Get.find` aqui.** Versões ligadas a controllers ficam em `app/widgets/` (ex.: `AppThemeToggle`).
- `InitialBinding(...).dependencies()` roda no `main` **antes** do `runApp` (o `GetMaterialApp` precisa do `ThemeController`).
- Persistência local via `KeyValueStore` (`SharedPreferencesKeyValueStore` / `InMemoryKeyValueStore` nos testes). **Não usar `get_storage`**: usa `dart:html` e quebra o build `--wasm`.
- Vitrine `/design` (só `kDebugMode`) substitui o Figma para validar o visual.
- Testes de widget: `test/helpers/pump_app.dart` (`pumpApp`, `testViewports` 390/820/1440, `brl()`).
  Fontes do Google desligadas em `test/flutter_test_config.dart`. Com `LoadingSkeleton` na tela, usar `pump(duração)`, não `pumpAndSettle`.

## Banco (Supabase local) — PR-03
- Migrations em `supabase/migrations/` (catálogo, admin/settings, RLS, storage). **RLS em todas as tabelas**:
  anon só lê o que está ativo; escrita só com `is_admin()` (`admin_users`). `admin_users` não aceita escrita via API.
- `store_settings` (linha única id=1) guarda nome, WhatsApp `5581986323686`, recado, loja aberta/fechada.
- Bucket `product-images`: público para leitura por URL, sem listagem; upload só admin; 5 MB; jpeg/png/webp.
- `config.toml`: `[auth] enable_signup = false` bloqueia cadastro. **Não** desligar `[auth.email] enable_signup`
  (nesta versão do CLI isso desliga o login por e-mail). `[analytics]` desligado (container vector falha no macOS).
- Testes pgTAP em `supabase/tests/database/` (papéis anon / logado comum / admin). Rodar `supabase test db`.
- `env/local.json` (fora do git) = URL local + `ANON_KEY` de `supabase status`.

## Como rodar / testar
```bash
supabase start && supabase db reset        # banco local + seed (mock p/ dev; Docker aberto)
supabase test db                           # pgTAP
cp env/example.json env/local.json         # env/*.json fora do git
fvm flutter run -d chrome --web-port 8080 --dart-define-from-file=env/local.json
# se o canal de debug do Chrome falhar, sirva o build de release:
fvm flutter run -d web-server --web-port 8080 --release --dart-define-from-file=env/local.json
fvm flutter analyze && fvm flutter test
fvm flutter test --run-skipped -t integration   # queries reais contra o Supabase local
```

## Decisões (ADR) / Requisitos
- ADRs: `docs/adr/README.md`
- SDD (requisitos, modelo de dados, fluxos, testes, roadmap): `docs/sdd/SDD.md`
- **Plano de execução do MVP (PR-01 a PR-11):** `docs/plano/PLANO-EXECUCAO-MVP.md`
- Referências visuais (substituem o Figma): `docs/design/referencias.md`
- Pendências: domínio, tabela de tamanhos.
