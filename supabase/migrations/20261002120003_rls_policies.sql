-- =============================================================================
-- Row Level Security (ADR-0002 · SDD §9.1)
--
-- A anon key é pública: o RLS é o controle de acesso REAL.
--   anon / authenticated → só leem o que está ativo
--   admin (is_admin())   → CRUD completo
-- =============================================================================

alter table public.categories        enable row level security;
alter table public.products          enable row level security;
alter table public.product_images    enable row level security;
alter table public.product_variants  enable row level security;
alter table public.store_settings    enable row level security;
alter table public.admin_users       enable row level security;

-- -----------------------------------------------------------------------------
-- categories
-- -----------------------------------------------------------------------------
create policy "categorias ativas são públicas"
  on public.categories for select
  to anon, authenticated
  using (is_active or (select public.is_admin()));

create policy "admin gerencia categorias"
  on public.categories for all
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- -----------------------------------------------------------------------------
-- products
-- -----------------------------------------------------------------------------
create policy "produtos ativos são públicos"
  on public.products for select
  to anon, authenticated
  using (is_active or (select public.is_admin()));

create policy "admin gerencia produtos"
  on public.products for all
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- -----------------------------------------------------------------------------
-- product_images (visíveis só se o produto estiver visível)
-- -----------------------------------------------------------------------------
create policy "imagens de produtos ativos são públicas"
  on public.product_images for select
  to anon, authenticated
  using (
    (select public.is_admin())
    or exists (
      select 1 from public.products p
      where p.id = product_images.product_id and p.is_active
    )
  );

create policy "admin gerencia imagens"
  on public.product_images for all
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- -----------------------------------------------------------------------------
-- product_variants (ativa + produto ativo)
-- -----------------------------------------------------------------------------
create policy "variantes ativas são públicas"
  on public.product_variants for select
  to anon, authenticated
  using (
    (select public.is_admin())
    or (
      is_active
      and exists (
        select 1 from public.products p
        where p.id = product_variants.product_id and p.is_active
      )
    )
  );

create policy "admin gerencia variantes"
  on public.product_variants for all
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- -----------------------------------------------------------------------------
-- store_settings (leitura pública: nome, WhatsApp, recado, loja aberta)
-- -----------------------------------------------------------------------------
create policy "configuração da loja é pública"
  on public.store_settings for select
  to anon, authenticated
  using (true);

create policy "admin altera configuração"
  on public.store_settings for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- -----------------------------------------------------------------------------
-- admin_users: cada admin enxerga só a própria linha; nenhuma escrita via API
-- -----------------------------------------------------------------------------
create policy "admin vê o próprio registro"
  on public.admin_users for select
  to authenticated
  using (user_id = (select auth.uid()));

revoke insert, update, delete on public.admin_users from anon, authenticated;

-- -----------------------------------------------------------------------------
-- Defesa em profundidade: o Supabase concede por padrão TRUNCATE/TRIGGER/
-- REFERENCES a anon/authenticated. RLS não cobre TRUNCATE; a API (PostgREST)
-- não emite esses comandos, mas não há motivo para mantê-los.
-- -----------------------------------------------------------------------------
revoke truncate, trigger, references on all tables in schema public from anon, authenticated;
alter default privileges in schema public
  revoke truncate, trigger, references on tables from anon, authenticated;
