# ADR-0002 — Supabase como backend (BaaS)

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

O projeto é pequeno (uma lojista, catálogo de dezenas/centenas de produtos) e precisa de:
banco relacional (estoque, pedidos, relatórios), upload de imagens, login para a dona e
regras de acesso (cliente anônimo só lê vitrine e cria pedido). Não queremos manter servidor.

## Decisão

Usar **Supabase** com:

| Recurso | Uso |
|---|---|
| **Postgres** | Catálogo, variantes (tamanho/cor), estoque, pedidos, visitas, relatórios (views). |
| **RLS (Row Level Security)** | Anônimo: `select` em produtos ativos; **nenhum** `insert` direto em pedidos. Admin: tudo. |
| **RPCs (funções `plpgsql`)** | `create_order`, `confirm_order`, `cancel_order`, `track_visit` — regras de negócio no banco, transacionais. |
| **Storage** | Bucket `product-images` (leitura pública, escrita só admin). |
| **Auth** | Login da Ana (ver ADR-0011). |
| **SDK** | `supabase_flutter` no app. Chaves via `--dart-define`. |

A `anon key` é pública por natureza; **a segurança vem do RLS + RPCs `security definer`**,
nunca de esconder a chave.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Firebase (Firestore) | NoSQL dificulta relatórios, joins e baixa de estoque transacional. |
| API própria (.NET / Java) + Postgres | Mais controle, porém custo de manter servidor e deploy para um projeto pequeno. |
| PocketBase | Simples, mas exige hospedar e tem ecossistema menor. |

## Consequências

**Positivas**
- Postgres "de verdade": constraints, transações, views para relatório, migrations SQL.
- Mesma base local e na nuvem (ADR-0008).

**Negativas / riscos**
- **Plano free pausa o projeto após ~7 dias sem uso** → avaliar plano Pro ao ir para produção
  ou um ping agendado (GitHub Actions / cron) enquanto estiver no free.
- Storage free limitado (1 GB) → imagens comprimidas no cliente antes do upload (máx. ~1600px, WebP/JPEG ~80%).
- Lógica em SQL exige testes de banco (pgTAP, ver SDD §10).
