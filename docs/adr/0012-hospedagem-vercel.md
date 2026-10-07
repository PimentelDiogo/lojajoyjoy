# ADR-0012 — Hospedagem do front-end (Vercel)

- **Status:** Proposto — configuração pronta no PR-11 (`web/vercel.json`, `deploy-vercel.yml`); aguarda conta/domínio
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

- Necessário configurar **domínio** (ex.: `joyjoy.com.br`) e atualizar a URL base
  usada no link do pedido (`APP_BASE_URL` via `--dart-define`).
- Atenção: a URL do site precisa estar nas **Redirect URLs** do Supabase Auth.

## Atualização (PR-11, 2026-10-07)

- `web/vercel.json`: rewrite SPA (rota direta responde 200, diferente do 404 do Pages), `Cache-Control`
  `must-revalidate` no código (os arquivos do Flutter não têm hash no nome), 1 dia em `assets/`, `icons/` e
  `canvaskit/`, 30 dias nas fontes; `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy`, `Permissions-Policy`.
- `.github/workflows/deploy-vercel.yml`: build no Actions e `vercel deploy build/web` (produção na `main`,
  preview em PR). Só roda com a variável `VERCEL_PROJECT_ID`.
- CSP ficou de fora: o Flutter carrega o CanvasKit e fontes de reserva do `gstatic` e precisa de
  `wasm-unsafe-eval`; uma CSP errada deixa a loja em branco. Revisar com o domínio final.
