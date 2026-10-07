# JOYJOY (lojajoyjoy) — Contexto

> Herda: global → `Projetos/CLAUDE.md` → este arquivo.

## Visão geral
Loja web de roupas **masculinas e femininas** da **Ana**. Link único (bio do Instagram,
WhatsApp, navegador). Landing → Feminino/Masculino → grid → carrinho → **pedido finalizado no
WhatsApp da Ana** com mensagem pronta. Admin da Ana: produtos (imagens, descrição, tamanhos,
cores), estoque, pedidos (baixa de estoque pelo link do pedido), relatórios de vendas e origem
dos clientes (Instagram × WhatsApp × site).

**Estágio:** PR-01 a PR-10 + CI na `main` (Marco 2: cliente pede → Ana confirma → estoque baixa). PR-11 (deploy de validação) na branch `feat/pr-11-deploy-validacao`; o que depende de conta/decisão está em `docs/plano/CHECKLIST-GO-LIVE.md`. Produção temporária: https://pimenteldiogo.github.io/lojajoyjoy/ com Supabase na nuvem (projeto `rwhduexczhpihdsitlro`, migrations aplicadas via `supabase db push`; catálogo vazio até o PR-09). Próximo: concluir o checklist de go-live (Marco 3: Ana validando). Novas branches saem da `main`.

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
- **RPCs (PR-07):** `create_order` (preço/estoque do banco, limites, loja aberta, antispam 5/h por sessão),
  `get_order_public` (sem dados do cliente para anon), `track_visit`. Funções novas NÃO nascem executáveis
  pela API (`alter default privileges`) — toda RPC pública precisa de `grant execute` + teste
  `has_function_privilege` no pgTAP. Função interna = `security invoker`.
- Features `order` (/finalizar, /pedido/:code; mensagem do WhatsApp só com dados do servidor via
  `OrderMessage.sanitize`) e `tracking` (`SessionTracker` global: sessão anônima 12 h + origem first-touch).
- **Features (PR-04):** `catalog` (landing + grid; a landing é a entrada do catálogo) e `store` (configuração
  da loja). **Exceções à regra "feature não importa feature":** `store` e `cart` são compartilhadas (globais, como o tema) —
  qualquer feature pode usar `StoreController`, `WhatsAppFab`, `StoreNotices` e `CartController`.
  Header das telas da vitrine: `actions: [AppCartButton(), AppThemeToggle()]`. Repositórios globais
  (`ProductRepository`, `CategoryRepository`, `StoreRepository`) ficam no `InitialBinding`.
- Componentes novos (PR-05): `ColorSelector`/`SizeSelector` (`option_selectors.dart`; opção esgotada fica riscada mas clicável p/ "Avise-me"), `QuantityStepper`, `ProductImage` (foto + placeholder). `SizeOrder` ordena PP→GG→números.
- Controllers por rota com parâmetro usam `tag` = parâmetro (ex.: `ProductDetailController` tag = slug).
- **Rodapé (`StoreFooter`, feature store):** home + fim do grid. Dados de `store_settings` (`instagram_handle`,
  `pickup_address`, `payment_methods`) — links montados no app (Instagram/Maps/WhatsApp), nunca URL do banco.
  Ícones de marca via `font_awesome_flutter` (`FaIconData`).
- **SnackBar com ação:** sempre `persist: false` + `duration` (no Flutter 3.44, com ação ele fica até tocar).
- Links externos só via `LinkLauncher` + `WhatsAppLink.build/tryBuild` (codifica o texto; valida o número).
- Fontes do Google são pré-carregadas no `main` (`AppTypography.preload`, timeout 3 s) — sem isso, chips
  cortavam o texto ao trocar de fonte.
- **Não teremos Figma.** O design é feito em conjunto, a partir de lojas de referência
  (screenshots via Playwright MCP) registradas em `docs/design/referencias.md`. Tokens no ADR-0009.

## CI/CD (ADR-0013)
- `.github/workflows/`: `ci.yml` (format `--set-exit-if-changed`, analyze, test, build wasm), `database.yml`
  (Supabase no runner + pgTAP + integração), `deploy-pages.yml` (main → GitHub Pages, `--base-href` do Pages,
  `404.html` = `index.html` para rotas da SPA). **Sempre rodar `fvm dart format lib test` antes do commit** — o CI reprova.
- Deploy usa Variables `SUPABASE_URL` / `SUPABASE_ANON_KEY` (públicas). **Nunca** usar a secret/service key no app, no repo ou em Variables. Na nuvem: cadastro público desligado, Site URL e Redirect `https://pimenteldiogo.github.io/lojajoyjoy/**`. Schema da nuvem só muda com `supabase db push` a partir da `main`. Hospedagem final (Vercel) segue no ADR-0012.

## Fluxo de PR (obrigatório)
- Branch `feat/pr-XX-nome` → testes → `flutter analyze` → **`/security-review` ao término de cada PR** → descrição (o que fez + impacto) → **pedir permissão** antes de abrir/mergear o PR.
- Definition of Done completo em `docs/plano/PLANO-EXECUCAO-MVP.md` §3.
- Flutter **3.44.9** fixado via **FVM** (`.fvmrc`) — sempre `fvm flutter ...` (o global é 3.19.6).
- Lint: `very_good_analysis`. `Result<T>` = `Success` | `Failed` (não usar `Error`, conflita com `dart:core`).
- **Rotas:** registrar toda página via `AppPages._page(...)` — aplica o `StrictRouteMiddleware` (o GetX casa
  rotas por prefixo e, sem isso, URL desconhecida abriria a landing em vez do 404).
- Admin local (seed, só dev): `ana@joyjoy.com.br`. Na nuvem usar outra senha forte.
- **Admin (PR-08):** `features/admin/` é carregado por **deferred import** (`admin_area.dart` + `DeferredView`).
  `AuthController` global (InitialBinding). `AdminGuard` é só UX — a segurança é RLS/RPC com `is_admin()`.
  Retorno pós-login só via `safeNextPath`. Telas do admin dentro do `AdminShell` (Rail no desktop, Drawer no celular).
- **Cadastro de peças (PR-09):** `features/admin/products`. Salvar = `SaveProduct` (valida → sobe fotos novas →
  RPC `save_product` → apaga fotos removidas; se a RPC falhar, apaga as que acabou de subir). Estoque vai como
  `stock` + `base_stock` (o banco aplica a diferença). Fotos: `ProductImagePicker` (web: `<input type=file>` +
  canvas, sem pacote; stub no VM). Admin **pode importar entidades de `catalog/domain`** (`Gender`, `Category`,
  `SizeOrder`) — é o modelo da loja.
- Telas do admin montadas fora de `Binding` usam `ControllerScope` (`app/widgets/`): cria o controller ao abrir
  e descarta ao sair (rebuild não recria; "nova peça" sempre começa vazia).
- `Obx` só observa o que é lido **no próprio builder** — widget filho que lê `.value` no `build` dele precisa do
  seu `Obx` (bug da busca/categoria no PR-09). `RxMap/RxList.assignAll` com coleção `const` → copiar antes.
- `Card` junta a semântica dos filhos (`semanticContainer: true`): em cards com vários botões usar `false`.
- `SegmentedButton` e `IconButton.filledTonal` usariam o azul do Masculino: tema/estilo com `primaryContainer`.
- **Pedidos (PR-10):** estoque só baixa em `confirm_order` (o pedido do cliente não reserva). `cancel_order` de
  confirmado estorna. Movimentos em `stock_movements` (só leitura para admin). `OrderController` recebe o
  `AuthController` (global, como `store`/`cart`) e só chama `ensureAdmin` se houver sessão. Admin pode importar
  entidades/widgets de `order` (`OrderStatus`, `OrderStatusChip`). Rótulos de origem: `TrafficSource.labelOf`.
- pgTAP: `reset role` NÃO limpa `request.jwt.claims` — ao voltar para anon, zerar o claim.
- **Fontes (PR-11):** embutidas em `assets/google_fonts/` (subset latino) com `allowRuntimeFetching = false`.
  Peso novo → arquivo + `AppTypography.bundledWeights` (teste confere). Como gerar: `assets/google_fonts/README.md`.
- **Senha (PR-11):** `PasswordRules` (≥ 10, letras e números) = `config.toml` = painel da nuvem. Recuperação:
  `/admin/nova-senha`, Supabase em `AuthFlowType.implicit` (link abre em qualquer navegador). Template pt-BR em
  `supabase/templates/recovery.html` (copiar no painel da nuvem).
- **Deploy:** `web/index.html` usa `__SITE_URL__` (og:url/og:image) — o deploy roda `tool/web/finalize_build.sh <SITE_URL>`.
  Vercel pronto (`web/vercel.json`, `deploy-vercel.yml`), ligado só com `VERCEL_PROJECT_ID`.

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
