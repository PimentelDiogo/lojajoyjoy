# JOYJOY

[![CI](https://github.com/PimentelDiogo/lojajoyjoy/actions/workflows/ci.yml/badge.svg)](https://github.com/PimentelDiogo/lojajoyjoy/actions/workflows/ci.yml)
[![Database](https://github.com/PimentelDiogo/lojajoyjoy/actions/workflows/database.yml/badge.svg)](https://github.com/PimentelDiogo/lojajoyjoy/actions/workflows/database.yml)
[![Deploy](https://github.com/PimentelDiogo/lojajoyjoy/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/PimentelDiogo/lojajoyjoy/actions/workflows/deploy-pages.yml)

Loja web de roupas femininas e masculinas com o pedido finalizado no WhatsApp da Ana.

**Stack:** Flutter Web · Clean Architecture · GetX (estado, DI e rotas) · Supabase.

- Decisões: [`docs/adr/`](docs/adr/README.md)
- Especificação: [`docs/sdd/SDD.md`](docs/sdd/SDD.md)
- Plano do MVP: [`docs/plano/PLANO-EXECUCAO-MVP.md`](docs/plano/PLANO-EXECUCAO-MVP.md)
- Referências visuais: [`docs/design/referencias.md`](docs/design/referencias.md)

## Pré-requisitos

| Ferramenta | Instalação |
|---|---|
| [FVM](https://fvm.app) | Versão do Flutter fixada em `.fvmrc` (**3.44.9**). Rode `fvm install` na raiz |
| Docker Desktop | Necessário para o Supabase local |
| Supabase CLI | `brew install supabase/tap/supabase` |

> Sempre use `fvm flutter ...` neste projeto (a máquina pode ter outra versão global).

## Rodando localmente

### 1. Banco (Supabase local — Docker precisa estar aberto)

```bash
supabase start          # sobe Postgres 17, API, Auth, Storage e Studio
supabase db reset       # recria o banco: migrations + seed (dados fictícios)
supabase test db        # testes pgTAP (RLS e regras)
```

| Serviço | URL |
|---|---|
| API | http://127.0.0.1:54321 |
| Studio (painel) | http://127.0.0.1:54323 |
| Postgres | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` |
| E-mails de teste (Mailpit) | http://127.0.0.1:54324 |

Admin local (seed): **ana@joyjoy.com.br**, com a senha provisória definida em `supabase/seed.sql`. Só vale no ambiente local.

### 2. App

```bash
fvm install                          # baixa o Flutter da versão do projeto
fvm flutter pub get

cp env/example.json env/local.json   # env/*.json fica fora do git
# cole a ANON_KEY de `supabase status` em env/local.json
fvm flutter run -d chrome --web-port 8080 --dart-define-from-file=env/local.json
```

## Qualidade

```bash
fvm dart format lib test
fvm flutter analyze                  # very_good_analysis
fvm flutter test
fvm flutter build web --release --wasm
```

## CI/CD (GitHub Actions — ADR-0013)

| Workflow | Quando | O que faz |
|---|---|---|
| `ci.yml` | todo push/PR | format, analyze, testes, build `--wasm` |
| `database.yml` | mudanças em `supabase/`, `data/`, integração | Supabase no runner + pgTAP + integração |
| `deploy-pages.yml` | push na `main` / manual | publica em https://pimenteldiogo.github.io/lojajoyjoy/ |

Configuração única no GitHub:
1. **Settings → Pages → Source: GitHub Actions**.
2. **Settings → Secrets and variables → Actions → Variables**: `SUPABASE_URL` e `SUPABASE_ANON_KEY`
   (do projeto Supabase na nuvem — PR-11).

## Estrutura

```
lib/
├── main.dart          # bootstrap (URL por path, Env)
├── app/               # GetMaterialApp, rotas, bindings, middlewares
├── core/              # config, errors (Result/Failure), usecase, state (UiState), pages
└── features/          # uma pasta por feature: data / domain / presentation
```
