-- =============================================================================
-- Administração e configurações da loja
-- ADR-0011 (auth admin) · referências A2/A14 (recado e loja fechada)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- admin_users: quem pode administrar a loja (a Ana e, no futuro, ajudantes)
-- -----------------------------------------------------------------------------
create table public.admin_users (
  user_id     uuid primary key references auth.users (id) on delete cascade,
  created_at  timestamptz not null default now()
);

comment on table public.admin_users is
  'Usuárias com acesso ao admin. Inserção só via SQL/Studio (sem API).';

-- Usada em TODAS as policies e RPCs de escrita. `security definer` para
-- conseguir ler admin_users mesmo com RLS ligado nela.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;

comment on function public.is_admin() is 'true se o usuário logado está em admin_users.';

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

-- -----------------------------------------------------------------------------
-- store_settings: linha única com a configuração da loja
-- -----------------------------------------------------------------------------
create table public.store_settings (
  id                   int primary key default 1 check (id = 1),
  store_name           text not null default 'JOYJOY',
  -- Formato wa.me: DDI + DDD + número, só dígitos.
  whatsapp_number      text not null check (whatsapp_number ~ '^[0-9]{12,13}$'),
  greeting_message     text not null default 'Olá! 👋 Quero fazer este pedido:'
                         check (length(greeting_message) <= 300),
  announcement         text check (length(announcement) <= 500),     -- recado da loja (A2)
  is_open              boolean not null default true,                -- loja fechada (A14)
  closed_message       text check (length(closed_message) <= 500),
  low_stock_threshold  int  not null default 2 check (low_stock_threshold >= 0),
  updated_at           timestamptz not null default now()
);

comment on table public.store_settings is 'Configuração da loja (sempre id = 1).';

create trigger store_settings_updated_at
  before update on public.store_settings
  for each row execute function public.set_updated_at();

-- Configuração real da loja (não é mock): WhatsApp da Ana.
insert into public.store_settings (id, store_name, whatsapp_number)
values (1, 'JOYJOY', '5581986323686');
