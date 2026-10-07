-- =============================================================================
-- PR-10 · Confirmar / cancelar pedido com baixa e estorno de estoque
-- ADR-0006 (estoque na variante, nunca negativo)
--
-- O pedido do cliente NÃO reserva estoque (create_order só confere). A baixa
-- acontece quando a Ana confirma a venda pelo link do pedido:
--   pending   --confirm_order-->  confirmed  (estoque − quantidade)
--   pending   --cancel_order--->  cancelled  (nada muda no estoque)
--   confirmed --cancel_order--->  cancelled  (estorno: estoque + quantidade)
-- Repetir a mesma ação não baixa/estorna de novo (idempotente).
-- =============================================================================

create type public.stock_reason as enum ('sale', 'sale_cancelled');

-- Histórico de movimentos de estoque (auditoria da Ana; relatórios no futuro).
create table public.stock_movements (
  id          uuid primary key default gen_random_uuid(),
  variant_id  uuid not null references public.product_variants (id),
  order_id    uuid references public.orders (id) on delete set null,
  delta       int  not null check (delta <> 0),
  reason      public.stock_reason not null,
  stock_after int  not null check (stock_after >= 0),
  created_by  uuid references auth.users (id),
  created_at  timestamptz not null default now()
);

create index stock_movements_variant_idx on public.stock_movements (variant_id, created_at desc);
create index stock_movements_order_idx on public.stock_movements (order_id);

alter table public.stock_movements enable row level security;

create policy "admin lê movimentos de estoque" on public.stock_movements
  for select to authenticated using ((select public.is_admin()));

revoke insert, update, delete, truncate, trigger, references
  on public.stock_movements from anon, authenticated;

alter table public.orders add column cancelled_by uuid references auth.users (id);

-- -----------------------------------------------------------------------------
-- O resumo do pedido passa a trazer datas/origem para a Ana (só privado).
-- -----------------------------------------------------------------------------
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
    'source', case when include_private then o.source end,
    'confirmed_at', case when include_private then o.confirmed_at end,
    'cancelled_at', case when include_private then o.cancelled_at end,
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
-- confirm_order: baixa o estoque de todos os itens, ou de nenhum.
-- -----------------------------------------------------------------------------
create or replace function public.confirm_order(p_code text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_order  public.orders;
  v_item   record;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into v_order
    from public.orders
   where code = upper(btrim(p_code))
   for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;

  if v_order.status = 'confirmed' then
    return public.order_payload(v_order.id, include_private => true); -- já baixado
  end if;
  if v_order.status <> 'pending' then
    raise exception 'invalid_status' using errcode = 'P0001', detail = v_order.status::text;
  end if;

  -- Trava as variantes em ordem fixa (evita deadlock entre duas confirmações).
  perform 1
     from public.product_variants v
    where v.id in (select i.variant_id from public.order_items i where i.order_id = v_order.id)
    order by v.id
      for update;

  for v_item in
    select i.variant_id, i.quantity, i.product_name, i.size, i.color_name, v.stock_qty
      from public.order_items i
      join public.product_variants v on v.id = i.variant_id
     where i.order_id = v_order.id
     order by i.variant_id
  loop
    if v_item.stock_qty < v_item.quantity then
      raise exception 'insufficient_stock' using
        errcode = 'P0001',
        detail = format('%s · Tam %s · %s (tem %s, pedido %s)',
                        v_item.product_name, v_item.size, v_item.color_name,
                        v_item.stock_qty, v_item.quantity);
    end if;

    update public.product_variants
       set stock_qty = stock_qty - v_item.quantity
     where id = v_item.variant_id;

    insert into public.stock_movements (variant_id, order_id, delta, reason, stock_after, created_by)
    values (v_item.variant_id, v_order.id, -v_item.quantity, 'sale',
            v_item.stock_qty - v_item.quantity, auth.uid());
  end loop;

  update public.orders
     set status = 'confirmed', confirmed_at = now(), confirmed_by = auth.uid()
   where id = v_order.id;

  return public.order_payload(v_order.id, include_private => true);
end;
$$;

-- -----------------------------------------------------------------------------
-- cancel_order: pendente só muda o status; confirmado devolve o estoque.
-- -----------------------------------------------------------------------------
create or replace function public.cancel_order(p_code text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_order  public.orders;
  v_item   record;
  v_after  int;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  select * into v_order
    from public.orders
   where code = upper(btrim(p_code))
   for update;
  if not found then
    raise exception 'order_not_found' using errcode = 'P0002';
  end if;

  if v_order.status = 'cancelled' then
    return public.order_payload(v_order.id, include_private => true); -- já cancelado
  end if;
  if v_order.status not in ('pending', 'confirmed') then
    raise exception 'invalid_status' using errcode = 'P0001', detail = v_order.status::text;
  end if;

  if v_order.status = 'confirmed' then
    for v_item in
      select i.variant_id, i.quantity
        from public.order_items i
       where i.order_id = v_order.id
       order by i.variant_id
    loop
      update public.product_variants
         set stock_qty = stock_qty + v_item.quantity
       where id = v_item.variant_id
      returning stock_qty into v_after;

      insert into public.stock_movements (variant_id, order_id, delta, reason, stock_after, created_by)
      values (v_item.variant_id, v_order.id, v_item.quantity, 'sale_cancelled', v_after, auth.uid());
    end loop;
  end if;

  update public.orders
     set status = 'cancelled', cancelled_at = now(), cancelled_by = auth.uid()
   where id = v_order.id;

  return public.order_payload(v_order.id, include_private => true);
end;
$$;

comment on function public.confirm_order(text) is 'Admin: confirma a venda e baixa o estoque (tudo ou nada; idempotente).';
comment on function public.cancel_order(text) is 'Admin: cancela o pedido; se já confirmado, devolve o estoque (idempotente).';

-- Default privileges já tiram o EXECUTE; o revoke explícito documenta.
revoke all on function public.confirm_order(text) from public, anon, authenticated;
revoke all on function public.cancel_order(text) from public, anon, authenticated;
grant execute on function public.confirm_order(text) to authenticated;
grant execute on function public.cancel_order(text) to authenticated;
