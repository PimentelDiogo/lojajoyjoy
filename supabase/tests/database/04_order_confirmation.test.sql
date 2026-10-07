-- =============================================================================
-- PR-10 · confirm_order / cancel_order — roda com `supabase test db`
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select ok(not has_function_privilege('anon', 'public.confirm_order(text)', 'execute'), 'anon NÃO executa confirm_order');
select ok(not has_function_privilege('anon', 'public.cancel_order(text)', 'execute'), 'anon NÃO executa cancel_order');
select ok(has_function_privilege('authenticated', 'public.confirm_order(text)', 'execute'), 'logado executa confirm_order (o is_admin decide)');
select ok(not has_function_privilege('anon', 'public.order_payload(uuid, boolean)', 'execute')
       and not has_function_privilege('authenticated', 'public.order_payload(uuid, boolean)', 'execute'),
  'order_payload (recriada) continua fora da API');
select is((select count(*)::int from pg_tables where schemaname = 'public' and not rowsecurity), 0,
  'stock_movements também tem RLS');

-- Variantes do seed (Vestido Midi Linho): P Rosa = 3, M Rosa = 1.
create temp table v as select
  (select id from public.product_variants where product_id = '20000000-0000-4000-a000-000000000001' and size = 'P' and color_name = 'Rosa') as p_rosa,
  (select id from public.product_variants where product_id = '20000000-0000-4000-a000-000000000001' and size = 'M' and color_name = 'Rosa') as m_rosa;
grant select on v to anon, authenticated;

create function pg_temp.stock(p_id uuid) returns int language sql as $$
  select stock_qty from public.product_variants where id = p_id
$$;
grant execute on function pg_temp.stock(uuid) to anon, authenticated;

-- Pedidos de teste: A (2× P), B (1× P + 2× M → falta M), C (1× M).
insert into public.orders (id, code, session_id, total) values
  ('cccc0000-0000-4000-a000-00000000000a', 'TSTAAA', gen_random_uuid(), 379.80),
  ('cccc0000-0000-4000-a000-00000000000b', 'TSTBBB', gen_random_uuid(), 569.70),
  ('cccc0000-0000-4000-a000-00000000000c', 'TSTCCC', gen_random_uuid(), 189.90);
insert into public.order_items (order_id, variant_id, product_name, size, color_name, unit_price, quantity) values
  ('cccc0000-0000-4000-a000-00000000000a', (select p_rosa from v), 'Vestido Midi Linho', 'P', 'Rosa', 189.90, 2),
  ('cccc0000-0000-4000-a000-00000000000b', (select p_rosa from v), 'Vestido Midi Linho', 'P', 'Rosa', 189.90, 1),
  ('cccc0000-0000-4000-a000-00000000000b', (select m_rosa from v), 'Vestido Midi Linho', 'M', 'Rosa', 189.90, 2),
  ('cccc0000-0000-4000-a000-00000000000c', (select m_rosa from v), 'Vestido Midi Linho', 'M', 'Rosa', 189.90, 1);

-- -----------------------------------------------------------------------------
-- Quem não é admin
-- -----------------------------------------------------------------------------
set local role anon;
select throws_ok($$ select public.confirm_order('TSTAAA') $$, '42501', null, 'anon não confirma');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-0000000000ff", "role": "authenticated"}';
select throws_ok($$ select public.confirm_order('TSTAAA') $$, 'forbidden', 'logado sem admin não confirma');
select throws_ok($$ select public.cancel_order('TSTAAA') $$, 'forbidden', 'logado sem admin não cancela');
select is((select count(*)::int from public.stock_movements), 0, 'logado sem admin não lê movimentos');
reset role;

-- -----------------------------------------------------------------------------
-- Ana
-- -----------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-00000000a0a0", "role": "authenticated"}';

select is(public.confirm_order(' tstaaa ') ->> 'status', 'confirmed', 'confirma pelo código (sem diferenciar maiúscula)');
select is(pg_temp.stock((select p_rosa from v)), 1, 'baixa: P Rosa 3 − 2 = 1');
select is(
  (select delta || '/' || reason || '/' || stock_after from public.stock_movements
    where order_id = 'cccc0000-0000-4000-a000-00000000000a'),
  '-2/sale/1', 'movimento de venda registrado'
);

select is(public.confirm_order('TSTAAA') ->> 'status', 'confirmed', 'confirmar de novo não dá erro');
select is(pg_temp.stock((select p_rosa from v)), 1, 'idempotente: não baixa duas vezes');

-- B pede 2× M, mas só há 1 → nada baixa (nem o P).
select throws_ok($$ select public.confirm_order('TSTBBB') $$, 'insufficient_stock', 'estoque insuficiente bloqueia a confirmação');
select is(pg_temp.stock((select p_rosa from v)), 1, 'tudo ou nada: P Rosa não foi baixado');
select is(pg_temp.stock((select m_rosa from v)), 1, 'tudo ou nada: M Rosa intacto');
select is((select status::text from public.orders where code = 'TSTBBB'), 'pending', 'pedido B continua pendente');

-- Cancelar confirmado → estorno.
select is(public.cancel_order('TSTAAA') ->> 'status', 'cancelled', 'cancela pedido confirmado');
select is(pg_temp.stock((select p_rosa from v)), 3, 'estorno: P Rosa volta para 3');
select is(
  (select delta || '/' || reason || '/' || stock_after from public.stock_movements
    where order_id = 'cccc0000-0000-4000-a000-00000000000a' and reason = 'sale_cancelled'),
  '2/sale_cancelled/3', 'movimento de estorno registrado'
);
select is(public.cancel_order('TSTAAA') ->> 'status', 'cancelled', 'cancelar de novo não dá erro');
select is(pg_temp.stock((select p_rosa from v)), 3, 'idempotente: não estorna duas vezes');
select throws_ok($$ select public.confirm_order('TSTAAA') $$, 'invalid_status', 'cancelado não pode ser confirmado');

-- Cancelar pendente não mexe no estoque.
select is(public.cancel_order('TSTCCC') ->> 'status', 'cancelled', 'cancela pedido pendente');
select is(pg_temp.stock((select m_rosa from v)), 1, 'pendente cancelado: estoque igual');

select throws_ok($$ select public.confirm_order('NAOEXISTE') $$, 'order_not_found', 'código inexistente');

select is(
  (select public.get_order_public('TSTAAA') ->> 'cancelled_at') is not null,
  true, 'Ana vê a data do cancelamento'
);
reset role;

-- Visitante continua sem dados privados (zera o JWT da Ana: `reset role` não zera).
set local request.jwt.claims = '{"role": "anon"}';
set local role anon;
select is(public.get_order_public('TSTAAA') ->> 'cancelled_at', null, 'anon não vê datas internas');
select is(public.get_order_public('TSTAAA') ->> 'status', 'cancelled', 'anon vê o status');
select is((select count(*)::int from public.stock_movements), 0, 'anon não lê movimentos');
select throws_ok(
  $$ insert into public.stock_movements (variant_id, delta, reason, stock_after) values ((select p_rosa from v), 1, 'sale', 1) $$,
  '42501', null, 'ninguém grava movimento direto pela API'
);
reset role;

select * from finish();
rollback;
