-- =============================================================================
-- Pedidos (checkout via WhatsApp) e origem do tráfego
-- ADR-0005 · ADR-0007 · SDD §8/§9 · requisitos do security review do PR-06
--
-- Regras de segurança:
--   * Ninguém (anon/authenticated) lê ou escreve `orders`/`order_items`/`visits`
--     direto pela API. Tudo passa pelas RPCs abaixo (security definer).
--   * O carrinho do cliente é entrada NÃO confiável: a RPC recebe só
--     variant_id + quantidade + observação e relê preço/estoque do banco.
-- =============================================================================

create type public.order_status    as enum ('pending', 'confirmed', 'cancelled', 'expired');
create type public.traffic_source  as enum ('instagram', 'whatsapp', 'facebook', 'busca', 'qrcode', 'site', 'outro');
create type public.delivery_method as enum ('pickup', 'delivery');
create type public.payment_method  as enum ('pix', 'card', 'cash');

-- Texto livre do cliente: caracteres de controle e quebras de linha viram um
-- espaço, espaços repetidos colapsados, cortado no limite. Null se vazio.
create or replace function public.clean_text(p_value text, p_max int)
returns text
language sql
immutable
set search_path = ''
as $$
  select nullif(
    left(
      btrim(regexp_replace(coalesce(p_value, ''), '[[:cntrl:][:space:]]+', ' ', 'g')),
      p_max
    ),
    ''
  );
$$;

-- Código curto e não sequencial (ex.: K7P2QX). Alfabeto sem 0/O/1/I/L.
create or replace function public.generate_order_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  v_alphabet constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  v_bytes bytea;
  v_code text;
begin
  loop
    v_bytes := extensions.gen_random_bytes(6);
    v_code := '';
    for i in 0..5 loop
      v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, i) % length(v_alphabet)) + 1, 1);
    end loop;
    exit when not exists (select 1 from public.orders where code = v_code);
  end loop;
  return v_code;
end;
$$;

-- -----------------------------------------------------------------------------
-- orders / order_items
-- -----------------------------------------------------------------------------
create table public.orders (
  id               uuid primary key default gen_random_uuid(),
  code             text not null unique,
  status           public.order_status not null default 'pending',
  source           public.traffic_source not null default 'site',
  session_id       uuid not null,
  customer_name    text check (length(customer_name) <= 60),
  customer_note    text check (length(customer_note) <= 300),
  delivery_method  public.delivery_method,
  payment_method   public.payment_method,
  total            numeric(10, 2) not null check (total >= 0),
  created_at       timestamptz not null default now(),
  confirmed_at     timestamptz,
  confirmed_by     uuid references auth.users (id),
  cancelled_at     timestamptz
);

create index orders_status_created_idx on public.orders (status, created_at desc);
create index orders_source_idx on public.orders (source);
create index orders_session_created_idx on public.orders (session_id, created_at desc);

create table public.order_items (
  id            uuid primary key default gen_random_uuid(),
  order_id      uuid not null references public.orders (id) on delete cascade,
  variant_id    uuid not null references public.product_variants (id),
  -- Snapshot: o histórico não muda se a Ana editar o produto depois.
  product_name  text not null,
  size          text not null,
  color_name    text not null,
  unit_price    numeric(10, 2) not null check (unit_price > 0),
  quantity      int not null check (quantity between 1 and 10),
  note          text check (length(note) <= 140),
  unique (order_id, variant_id)
);

create index order_items_order_idx on public.order_items (order_id);

-- -----------------------------------------------------------------------------
-- visits (origem do tráfego — ADR-0007). Sem dados pessoais (LGPD).
-- -----------------------------------------------------------------------------
create table public.visits (
  session_id     uuid primary key,
  source         public.traffic_source not null,
  utm_campaign   text check (length(utm_campaign) <= 80),
  referrer_host  text check (length(referrer_host) <= 120),
  landing_path   text check (length(landing_path) <= 200),
  device_type    text check (device_type in ('mobile', 'tablet', 'desktop')),
  created_at     timestamptz not null default now()
);

create index visits_created_source_idx on public.visits (created_at, source);

-- -----------------------------------------------------------------------------
-- RLS: nada direto pela API. Admin lê (relatórios/pedidos no PR-08+).
-- -----------------------------------------------------------------------------
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;
alter table public.visits      enable row level security;

create policy "admin lê pedidos" on public.orders
  for select to authenticated using ((select public.is_admin()));
create policy "admin lê itens de pedidos" on public.order_items
  for select to authenticated using ((select public.is_admin()));
create policy "admin lê visitas" on public.visits
  for select to authenticated using ((select public.is_admin()));

revoke insert, update, delete, truncate, trigger, references
  on public.orders, public.order_items, public.visits
  from anon, authenticated;

-- -----------------------------------------------------------------------------
-- RPC: create_order
-- -----------------------------------------------------------------------------
create or replace function public.create_order(
  p_items          jsonb,
  p_session_id     uuid,
  p_source         public.traffic_source default 'site',
  p_customer_name  text default null,
  p_customer_note  text default null,
  p_delivery       public.delivery_method default null,
  p_payment        public.payment_method default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  c_max_items      constant int := 20;
  c_max_qty        constant int := 10;
  c_rate_limit     constant int := 5;   -- pedidos por sessão por hora
  v_settings       public.store_settings;
  v_order_id       uuid;
  v_code           text;
  v_total          numeric(10, 2) := 0;
  v_item           record;
  v_count          int;
  v_cart           jsonb;
begin
  if p_session_id is null then
    raise exception 'invalid_session' using errcode = '22023';
  end if;

  select * into v_settings from public.store_settings where id = 1;
  if not coalesce(v_settings.is_open, false) then
    raise exception 'store_closed' using errcode = 'P0001';
  end if;

  -- Antispam simples por sessão (o cliente gera o session_id; é um freio,
  -- não uma barreira forte — ver docs).
  select count(*) into v_count
    from public.orders
   where session_id = p_session_id
     and created_at > now() - interval '1 hour';
  if v_count >= c_rate_limit then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'empty_cart' using errcode = '22023';
  end if;

  -- Normaliza a entrada: agrega variant_id repetido e limpa a observação.
  -- Qualquer outro campo enviado pelo cliente (preço, nome…) é ignorado.
  select coalesce(jsonb_agg(jsonb_build_object(
           'variant_id', variant_id, 'quantity', quantity, 'note', note)), '[]'::jsonb)
    into v_cart
    from (
      select (e->>'variant_id')::uuid                as variant_id,
             sum((e->>'quantity')::int)::int         as quantity,
             public.clean_text(max(e->>'note'), 140) as note
        from jsonb_array_elements(p_items) e
       group by 1
    ) normalized;

  if jsonb_array_length(v_cart) > c_max_items then
    raise exception 'too_many_items' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_to_recordset(v_cart) c(variant_id uuid, quantity int, note text)
     where c.variant_id is null or c.quantity is null or c.quantity < 1 or c.quantity > c_max_qty
  ) then
    raise exception 'invalid_quantity' using errcode = '22023';
  end if;

  -- Preço e estoque SEMPRE do banco; variante e produto precisam estar ativos.
  for v_item in
    select c.variant_id, c.quantity, c.note,
           v.stock_qty, v.size, v.color_name, v.is_active as variant_active,
           p.name as product_name, p.is_active as product_active,
           coalesce(v.price_override, p.base_price) as unit_price
      from jsonb_to_recordset(v_cart) c(variant_id uuid, quantity int, note text)
      left join public.product_variants v on v.id = c.variant_id
      left join public.products p on p.id = v.product_id
  loop
    if v_item.stock_qty is null or not v_item.variant_active or not v_item.product_active then
      raise exception 'variant_unavailable' using errcode = 'P0001', detail = v_item.variant_id::text;
    end if;
    if v_item.stock_qty < v_item.quantity then
      raise exception 'insufficient_stock' using errcode = 'P0001', detail = v_item.variant_id::text;
    end if;
    v_total := v_total + v_item.unit_price * v_item.quantity;
  end loop;

  v_code := public.generate_order_code();
  insert into public.orders (
    code, session_id, source, customer_name, customer_note,
    delivery_method, payment_method, total
  ) values (
    v_code, p_session_id, coalesce(p_source, 'site'),
    public.clean_text(p_customer_name, 60), public.clean_text(p_customer_note, 300),
    p_delivery, p_payment, v_total
  )
  returning id into v_order_id;

  insert into public.order_items (order_id, variant_id, product_name, size, color_name, unit_price, quantity, note)
  select v_order_id, c.variant_id, p.name, v.size, v.color_name,
         coalesce(v.price_override, p.base_price), c.quantity, c.note
    from jsonb_to_recordset(v_cart) c(variant_id uuid, quantity int, note text)
    join public.product_variants v on v.id = c.variant_id
    join public.products p on p.id = v.product_id;

  return public.order_payload(v_order_id, include_private => true);
end;
$$;

-- Monta o JSON do pedido. `include_private` (nome/obs do cliente) só para a
-- resposta do create_order — a página pública não expõe dados do cliente.
create or replace function public.order_payload(p_order_id uuid, include_private boolean default false)
returns jsonb
language sql
stable
security invoker  -- interna: roda com os privilégios de quem chama (as RPCs definer)
set search_path = ''
as $$
  select jsonb_build_object(
    'code', o.code,
    'status', o.status,
    'total', o.total,
    'created_at', o.created_at,
    'delivery_method', o.delivery_method,
    'payment_method', o.payment_method,
    'customer_name', case when include_private then o.customer_name end,
    'customer_note', case when include_private then o.customer_note end,
    'items', coalesce((
      select jsonb_agg(jsonb_build_object(
               'product_name', i.product_name,
               'size', i.size,
               'color_name', i.color_name,
               'unit_price', i.unit_price,
               'quantity', i.quantity,
               'note', case when include_private then i.note end
             ) order by i.product_name, i.size)
        from public.order_items i
       where i.order_id = o.id
    ), '[]'::jsonb)
  )
  from public.orders o
  where o.id = p_order_id;
$$;

-- -----------------------------------------------------------------------------
-- RPC: get_order_public — resumo para /pedido/:code (sem dados do cliente)
-- -----------------------------------------------------------------------------
create or replace function public.get_order_public(p_code text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select public.order_payload(o.id, include_private => (select public.is_admin()))
    from public.orders o
   where o.code = upper(btrim(p_code));
$$;

-- -----------------------------------------------------------------------------
-- RPC: track_visit — 1 registro por sessão (first-touch)
-- -----------------------------------------------------------------------------
create or replace function public.track_visit(
  p_session_id     uuid,
  p_source         public.traffic_source,
  p_utm_campaign   text default null,
  p_referrer_host  text default null,
  p_landing_path   text default null,
  p_device_type    text default null
)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into public.visits (session_id, source, utm_campaign, referrer_host, landing_path, device_type)
  values (
    p_session_id,
    coalesce(p_source, 'site'),
    public.clean_text(p_utm_campaign, 80),
    public.clean_text(p_referrer_host, 120),
    public.clean_text(p_landing_path, 200),
    case when p_device_type in ('mobile', 'tablet', 'desktop') then p_device_type end
  )
  on conflict (session_id) do nothing;
$$;

-- Permissões das funções: só as RPCs públicas ficam expostas.
-- ATENÇÃO: no Supabase, funções novas recebem EXECUTE direto para anon e
-- authenticated (não só via PUBLIC). Por isso o revoke é explícito nos 3.
revoke all on function public.clean_text(text, int) from public, anon, authenticated;
revoke all on function public.generate_order_code() from public, anon, authenticated;
revoke all on function public.order_payload(uuid, boolean) from public, anon, authenticated;
revoke all on function public.create_order(jsonb, uuid, public.traffic_source, text, text, public.delivery_method, public.payment_method) from public, anon, authenticated;
revoke all on function public.get_order_public(text) from public, anon, authenticated;
revoke all on function public.track_visit(uuid, public.traffic_source, text, text, text, text) from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;

-- Daqui em diante, funções novas no schema public NÃO nascem executáveis
-- pela API: cada RPC pública precisa de grant explícito.
alter default privileges in schema public
  revoke execute on functions from public, anon, authenticated;

grant execute on function public.create_order(jsonb, uuid, public.traffic_source, text, text, public.delivery_method, public.payment_method) to anon, authenticated;
grant execute on function public.get_order_public(text) to anon, authenticated;
grant execute on function public.track_visit(uuid, public.traffic_source, text, text, text, text) to anon, authenticated;
