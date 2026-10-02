# ADR-0012 — Hospedagem do front-end (Vercel)

- **Status:** Proposto *(não decidido — revisar antes do primeiro deploy)*
- **Data:** 2026-10-02

## Contexto

O build do Flutter Web gera arquivos estáticos (`build/web`). Precisamos de hospedagem com
HTTPS, domínio próprio, CDN, cache de assets e **rewrite SPA** (rotas como `/pedido/K7P2QX`
precisam servir `index.html` no refresh/abertura direta).

## Proposta

**Vercel** como hospedagem estática:

```json
// vercel.json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }],
  "headers": [
    { "source": "/assets/(.*)", "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] },
    { "source": "/index.html", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] }
  ]
}
```

- Vercel não tem Flutter na imagem de build → **build no GitHub Actions** (`flutter build web --release --wasm`
  com `--dart-define`) e deploy do `build/web` via `vercel deploy --prebuilt` (ou action oficial).
- Preview deploy por branch para a Ana validar antes de ir ao ar.

## Alternativas

| Opção | Prós | Contras |
|---|---|---|
| **Vercel** | Previews por PR, DX ótima, CDN | Build Flutter precisa ser externo |
| Cloudflare Pages | CDN excelente, banda ilimitada no free | Mesma limitação de build |
| Firebase Hosting | Integração Flutter conhecida | Mais um provedor além do Supabase |
| Netlify | Similar à Vercel | — |

## Consequências (se aceito)

- Necessário configurar **domínio** (ex.: `ondasquefaltam.com.br`) e atualizar a URL base
  usada no link do pedido (`APP_BASE_URL` via `--dart-define`).
- Atenção: a URL do site precisa estar nas **Redirect URLs** do Supabase Auth.
