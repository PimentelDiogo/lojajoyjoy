# ADR-0008 — Ambiente local com Supabase CLI (Postgres) e migrations versionadas

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

Requisito: testar localmente com **Postgres**, guardando **migrations** que depois possam ser
aplicadas no Supabase da nuvem sem retrabalho.

Ponto de atenção: um Postgres "puro" (ex.: `docker run postgres`) **não tem** os schemas e
roles do Supabase (`auth.users`, `auth.uid()`, `storage.objects`, roles `anon`/`authenticated`).
Nossas policies RLS e RPCs dependem deles — migrations testadas em Postgres puro **quebrariam**
ou precisariam de "gambiarras" locais.

## Decisão

Usar o **Supabase CLI**, que sobe localmente (via Docker) um **Postgres 15** idêntico ao da
nuvem + Auth + Storage + Studio.

```
supabase/
├── config.toml
├── migrations/                 # fonte da verdade do schema (SQL versionado no git)
│   ├── 20261002000001_init_catalog.sql
│   ├── 20261002000002_orders.sql
│   ├── 20261002000003_stock_movements.sql
│   ├── 20261002000004_visits_and_reports.sql
│   ├── 20261002000005_rls_policies.sql
│   └── 20261002000006_storage_bucket.sql
├── seed.sql                    # dados fictícios SÓ para dev local
└── tests/                      # testes pgTAP das RPCs e policies
    └── confirm_order_test.sql
```

### Fluxo

```mermaid
flowchart LR
    DEV["supabase migration new &lt;nome&gt;"] --> SQL["Edita o .sql"]
    SQL --> RESET["supabase db reset<br/>(recria local + seed)"]
    RESET --> TEST["supabase test db<br/>(pgTAP)"]
    TEST --> GIT["commit no git"]
    GIT --> PUSH["supabase link + supabase db push<br/>(aplica na nuvem)"]
```

| Comando | Função |
|---|---|
| `supabase start` | Sobe Postgres (porta 54322), API (54321) e Studio (54323). |
| `supabase migration new init_catalog` | Cria migration com timestamp. |
| `supabase db reset` | Recria o banco local aplicando todas as migrations + `seed.sql`. |
| `supabase test db` | Roda testes pgTAP. |
| `supabase db push` | Aplica migrations pendentes no projeto remoto. |

- O **Postgres local é acessível normalmente** (`postgresql://postgres:postgres@localhost:54322/postgres`)
  — dá para usar DBeaver/psql como em qualquer Postgres.
- `seed.sql` é **mock** com o motivo de: permitir desenvolver a vitrine e os relatórios sem
  depender da Ana cadastrar produtos reais. **Nunca** roda na nuvem.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Postgres puro via docker-compose | Sem `auth`/`storage`/roles → RLS e RPCs não testáveis fielmente. |
| Desenvolver direto no Supabase cloud | Sem histórico versionado, risco de alterar dados reais. |
| Flyway / Liquibase | Funciona, mas duplica o que o CLI já faz com o Supabase. |

## Consequências

- **+** Paridade local ↔ nuvem; schema 100% versionado.
- **−** Requer **Docker Desktop** rodando e o CLI (`brew install supabase/tap/supabase`).
- **−** Mudanças feitas pelo Studio da nuvem devem ser trazidas com `supabase db diff` — regra:
  **schema só muda por migration**.
