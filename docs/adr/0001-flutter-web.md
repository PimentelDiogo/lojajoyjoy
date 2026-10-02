# ADR-0001 — Flutter Web como plataforma do site

- **Status:** Aceito
- **Data:** 2026-10-02

## Contexto

A loja precisa de **um link** que funcione:
- dentro do **navegador embutido do Instagram** (link da bio / stories);
- quando enviado pelo **WhatsApp**;
- aberto direto em qualquer navegador (desktop ou celular).

O dono do projeto (Diogo) é especialista em Flutter, e há interesse futuro em app mobile.
O tráfego virá quase 100% de links compartilhados — **SEO orgânico não é prioridade**.

## Decisão

Usar **Flutter Web** (canal stable, Dart 3) com:

- **Renderer:** build padrão (`flutter build web`), habilitando `--wasm` (skwasm) quando o
  navegador suportar, com fallback automático para CanvasKit.
- **URL strategy por path** (`usePathUrlStrategy()`), para links limpos:
  `/feminino`, `/produto/vestido-midi`, `/pedido/K7P2QX` (sem `#`).
- **Deferred loading** (`import ... deferred as admin`) do módulo administrativo, para que o
  cliente final **não baixe** o código da área da Ana.
- **Splash em HTML puro** no `web/index.html` enquanto o Flutter carrega (evita tela branca
  no Instagram, que é onde o cliente tem menos paciência).
- **Meta tags Open Graph estáticas** no `index.html` (título, descrição, imagem) para o preview
  do link no WhatsApp/Instagram.

## Alternativas consideradas

| Alternativa | Por que não |
|---|---|
| Next.js / Nuxt (SSR) | Melhor SEO e first-load, mas sai da stack de domínio do Diogo e não reaproveita para app mobile. |
| Vue SPA | Mesmo motivo; não há ganho relevante, já que SEO não é requisito. |
| Flutter mobile + PWA | Instagram não instala PWA; o link precisa abrir direto. |

## Consequências

**Positivas**
- Um único código para web hoje e Android/iOS amanhã.
- UI consistente pixel a pixel entre navegadores.

**Negativas / riscos**
- **Primeiro carregamento pesado** (~2–3 MB). Mitigação: splash HTML, deferred loading do
  admin, imagens otimizadas, cache agressivo dos assets no host.
- **SEO fraco** (conteúdo renderizado em canvas). Aceito: o canal é Instagram/WhatsApp.
- Peculiaridades do **in-app browser do Instagram** (cookies/localStorage podem ser limpos,
  `window.open` limitado). Mitigação: abrir o `wa.me` na mesma aba (`_self`) e não depender
  de persistência de longo prazo do carrinho.
- Hospedagem precisa de **rewrite SPA** (todas as rotas → `index.html`). Ver ADR-0012.
