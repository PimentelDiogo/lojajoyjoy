# Ondas que Faltam (lojajoyjoy) — Contexto

> Herda: global → `Projetos/CLAUDE.md` → este arquivo.

## Visão geral
Loja web de roupas **masculinas e femininas** da **Ana**. Link único (bio do Instagram,
WhatsApp, navegador). Landing → Feminino/Masculino → grid → carrinho → **pedido finalizado no
WhatsApp da Ana** com mensagem pronta. Admin da Ana: produtos (imagens, descrição, tamanhos,
cores), estoque, pedidos (baixa de estoque pelo link do pedido), relatórios de vendas e origem
dos clientes (Instagram × WhatsApp × site).

**Estágio:** PR-01 (bootstrap) implementado na branch `feat/pr-01-bootstrap`.

**WhatsApp da Ana:** +55 81 98632-3686 → `5581986323686` (fica em `store_settings`, não no código).

## Stack
- **Flutter Web** (Dart 3) — ADR-0001
- **Clean Architecture** organizada por feature — ADR-0004
- **GetX** para **gerência de estado, injeção de dependência e rotas** (`GetMaterialApp`, `GetMiddleware`) — ADR-0003
- **Supabase**: Postgres, RLS, RPCs plpgsql, Auth, Storage — ADR-0002
- Local: **Supabase CLI** (Postgres 15 em Docker), migrations em `supabase/migrations` — ADR-0008
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

## Como rodar / testar
```bash
supabase start && supabase db reset        # banco local + seed (mock p/ dev)
supabase test db                           # pgTAP
cp env/example.json env/local.json         # env/*.json fora do git
fvm flutter run -d chrome --web-port 8080 --dart-define-from-file=env/local.json
fvm flutter analyze && fvm flutter test
```

## Decisões (ADR) / Requisitos
- ADRs: `docs/adr/README.md`
- SDD (requisitos, modelo de dados, fluxos, testes, roadmap): `docs/sdd/SDD.md`
- **Plano de execução do MVP (PR-01 a PR-11):** `docs/plano/PLANO-EXECUCAO-MVP.md`
- Referências visuais (substituem o Figma): `docs/design/referencias.md`
- Pendências: domínio, tabela de tamanhos, logo, aprovar os itens das referências (§4).
