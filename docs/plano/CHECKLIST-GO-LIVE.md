# Checklist para colocar a JOYJOY no ar (PR-11)

> O que já está no código está marcado como ✅. O resto depende de conta, decisão ou teste no celular.

## 1. Segurança e contas

- [ ] **Revogar a secret key** colada no chat (Supabase → Project Settings → API Keys → `sb_secret_…` → Revoke). Nunca usar no app.
- [ ] **Criar a conta da Ana na nuvem** (Supabase → Authentication → Users → Add user):
  - e-mail `ana@joyjoy.com.br`, **senha forte** (≥ 10, letras e números; não usar a do seed);
  - marcar "Auto Confirm User".
  - Depois, no SQL Editor:
    ```sql
    insert into public.admin_users (user_id)
    select id from auth.users where email = 'ana@joyjoy.com.br';
    ```
- [ ] **Política de senha** (Authentication → Passwords): mínimo **10**, "Letters and digits" — igual ao app.
- [ ] **Proteção contra senha vazada** (mesma tela), se o plano permitir.
- [ ] **Secure password change** ligado (Authentication → Providers → Email): trocar a senha exige login recente — o link de recuperação continua funcionando (testado).

## 2. E-mail ("Esqueci minha senha")

- ✅ App: tela "Esqueci minha senha" + página `/admin/nova-senha` (funciona mesmo abrindo o e-mail em outro navegador).
- [ ] **SMTP próprio** (Authentication → Emails → SMTP Settings). O SMTP padrão do Supabase só envia para
  membros do time do projeto e tem limite baixo. Sugestão: **Resend** (plano grátis) com remetente `nao-responda@<domínio>`.
- [ ] Redirect URLs (Authentication → URL Configuration) já cobrem `https://pimenteldiogo.github.io/lojajoyjoy/**`.
  Ao trocar de domínio, adicionar `https://<domínio>/**` e mudar o **Site URL**.
  - ⚠️ **Nunca** adicionar `https://*.vercel.app/**`: qualquer pessoa publica um site em `*.vercel.app` e
    poderia receber o token do link de "nova senha". Liberar só o domínio final (ou o subdomínio exato do projeto).

## 3. Hospedagem (ADR-0012)

- ✅ `web/vercel.json` (rewrite da SPA, cache, cabeçalhos de segurança) e `.github/workflows/deploy-vercel.yml`
  (desligado até existir a variável `VERCEL_PROJECT_ID`).
- [ ] Decidir: **Vercel** (recomendado) × manter GitHub Pages × Cloudflare Pages.
- [ ] Se Vercel: criar o projeto (sem build — o build é no GitHub Actions), gerar token e configurar no GitHub:
  - Secret `VERCEL_TOKEN`
  - Variables `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`, `SITE_URL` (ex.: `https://joyjoy.com.br/`)
- [ ] **Domínio** (ex.: `joyjoy.com.br`) apontado para a hospedagem.

| | GitHub Pages (hoje) | Vercel |
|---|---|---|
| Rota direta (`/pedido/X`) | abre, mas responde **404** (via `404.html`) | 200 (rewrite) |
| Cache | 10 min fixo (às vezes precisa Cmd+Shift+R) | controlado (`vercel.json`) |
| Domínio próprio | sim | sim |
| Preview por PR | não | sim |

## 4. Testes no celular (antes de mandar para a Ana)

- [ ] iPhone: abrir o link pela **bio do Instagram** e por uma conversa do **WhatsApp** (navegador embutido).
- [ ] Android: idem.
- [ ] Em cada um: landing → seção → peça → carrinho → finalizar → WhatsApp abre com a mensagem.
- [ ] Preview do link no WhatsApp mostra a imagem (og:image) — ✅ URL absoluta gerada no deploy.
- [ ] Ana: login, cadastrar 1 peça com foto do celular, confirmar 1 pedido de teste.

## 5. Conteúdo

- [ ] Ana aprovar o escopo (catálogo de demonstração).
- [ ] **Remover a demonstração** antes do cadastro real:
  `supabase db query --linked -f supabase/demo/remove_demo_catalog.sql` (apaga também as categorias demo — a Ana cria as dela no formulário).
- [ ] Tabela de medidas (pendente).

## 6. Entrega para a Ana

- Login: `https://<site>/admin/login`
- Links oficiais (contam a origem no painel):
  - Bio do Instagram: `https://<site>/?src=instagram`
  - WhatsApp: `https://<site>/?src=whatsapp`
