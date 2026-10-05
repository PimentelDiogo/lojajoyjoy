-- =============================================================================
-- Pedidos e origem (PR-07): create_order, get_order_public, track_visit
-- Cada requisito do security review do PR-06 tem um teste aqui.
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- Variantes do seed (por SKU)
create temporary table v as
select sku, id from public.product_variants;
grant select on v to anon, authenticated;

create temporary table session as select gen_random_uuid() as id;
grant select on session to anon, authenticated;

-- -----------------------------------------------------------------------------
-- Estrutura e acesso direto
-- -----------------------------------------------------------------------------
select is(
  (select count(*)::int from pg_tables where schemaname = 'public' and not rowsecurity),
  0,
  'RLS ligado em todas as tabelas (inclui orders, order_items, visits)'
);

set local role anon;

select throws_ok(
  $$ insert into public.orders (code, session_id, total) values ('HACK01', gen_random_uuid(), 0) $$,
  '42501', null, 'anon: não insere pedido direto'
);
select is((select count(*)::int from public.orders), 0, 'anon: não lê pedidos direto');
select throws_ok(
  $$ insert into public.visits (session_id, source) values (gen_random_uuid(), 'site') $$,
  '42501', null, 'anon: não insere visita direto'
);

-- Funções internas NÃO podem ser chamadas pela API (security review do PR-07).
select ok(
  not has_function_privilege('anon', 'public.order_payload(uuid, boolean)', 'execute')
  and not has_function_privilege('authenticated', 'public.order_payload(uuid, boolean)', 'execute'),
  'order_payload não é executável por anon/authenticated'
);
select ok(
  not has_function_privilege('anon', 'public.clean_text(text, int)', 'execute')
  and not has_function_privilege('anon', 'public.generate_order_code()', 'execute')
  and not has_function_privilege('anon', 'public.set_updated_at()', 'execute'),
  'clean_text, generate_order_code e set_updated_at não são executáveis por anon'
);
select ok(
  has_function_privilege('anon', 'public.create_order(jsonb, uuid, public.traffic_source, text, text, public.delivery_method, public.payment_method)', 'execute')
  and has_function_privilege('anon', 'public.get_order_public(text)', 'execute')
  and has_function_privilege('anon', 'public.track_visit(uuid, public.traffic_source, text, text, text, text)', 'execute')
  and has_function_privilege('anon', 'public.is_admin()', 'execute'),
  'só as RPCs públicas (e is_admin, usada nas policies) ficam expostas'
);
select throws_ok(
  $$ select public.order_payload(gen_random_uuid(), true) $$,
  '42501', null,
  'anon chamando order_payload direto → permissão negada'
);

-- -----------------------------------------------------------------------------
-- create_order: caminho feliz
-- -----------------------------------------------------------------------------
create temporary table result as
select public.create_order(
  jsonb_build_array(
    -- Preço/nome forjados pelo cliente devem ser IGNORADOS.
    jsonb_build_object('variant_id', (select id from v where sku = 'VML-P-ROS'),
                       'quantity', 2, 'price', 1, 'name', 'Grátis',
                       'note', E'  barra\n*2 cm*  '),
    jsonb_build_object('variant_id', (select id from v where sku = 'VTA-P-PRE'), 'quantity', 1),
    -- Repetido: deve ser agregado (1 + 1 = 2).
    jsonb_build_object('variant_id', (select id from v where sku = 'VTA-P-PRE'), 'quantity', 1)
  ),
  (select id from session),
  'instagram',
  E'Maria\u0007 da Silva',
  'posso retirar sábado?',
  'pickup',
  'pix'
) as payload;
grant select on result to authenticated;

select matches(
  (select payload->>'code' from result),
  '^[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{6}$',
  'código de 6 caracteres sem ambíguos (0/O/1/I/L)'
);
select is(
  (select (payload->>'total')::numeric from result),
  189.90 * 2 + 98.00 * 2,
  'total calculado com o preço DO BANCO (preço do cliente ignorado)'
);
select is(
  (select jsonb_array_length(payload->'items') from result),
  2,
  'variante repetida agregada em um item'
);
select is(
  (select (i->>'quantity')::int from result, jsonb_array_elements(payload->'items') i
    where i->>'product_name' = 'Vestido Tule Alcinha'),
  2,
  'quantidade da variante repetida somada'
);
select is(
  (select i->>'product_name' from result, jsonb_array_elements(payload->'items') i
    where (i->>'unit_price')::numeric = 189.90),
  'Vestido Midi Linho',
  'nome do produto vem do banco (nome do cliente ignorado)'
);
select is(
  (select payload->>'customer_name' from result),
  'Maria da Silva',
  'nome do cliente sem caracteres de controle'
);
select is(
  (select i->>'note' from result, jsonb_array_elements(payload->'items') i
    where i->>'product_name' = 'Vestido Midi Linho'),
  'barra *2 cm*',
  'observação: quebra de linha removida e espaços aparados'
);

reset role;
select is(
  (select stock_qty from public.product_variants where sku = 'VML-P-ROS'),
  3,
  'criar pedido NÃO baixa estoque (só a Ana na confirmação — ADR-0006)'
);
select is(
  (select status::text || '/' || source::text || '/' || delivery_method::text || '/' || payment_method::text
     from public.orders where code = (select payload->>'code' from result)),
  'pending/instagram/pickup/pix',
  'pedido gravado como pending com origem, entrega e pagamento'
);
set local role anon;

-- -----------------------------------------------------------------------------
-- create_order: validações
-- -----------------------------------------------------------------------------
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'VML-G-ROS'), 'quantity', 1)),
       gen_random_uuid()) $$,
  'P0001', 'insufficient_stock', 'variante esgotada → insufficient_stock'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'VML-P-ROS'), 'quantity', 4)),
       gen_random_uuid()) $$,
  'P0001', 'insufficient_stock', 'quantidade acima do estoque → insufficient_stock'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CL-M-VER'), 'quantity', 1)),
       gen_random_uuid()) $$,
  'P0001', 'variant_unavailable', 'produto inativo → variant_unavailable'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', gen_random_uuid(), 'quantity', 1)), gen_random_uuid()) $$,
  'P0001', 'variant_unavailable', 'variante inexistente → variant_unavailable'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CB-P-BRA'), 'quantity', 11)),
       gen_random_uuid()) $$,
  '22023', 'invalid_quantity', 'quantidade > 10 → invalid_quantity'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CB-P-BRA'), 'quantity', 0)),
       gen_random_uuid()) $$,
  '22023', 'invalid_quantity', 'quantidade 0 → invalid_quantity'
);
select throws_ok(
  $$ select public.create_order('[]'::jsonb, gen_random_uuid()) $$,
  '22023', 'empty_cart', 'carrinho vazio → empty_cart'
);
select throws_ok(
  $$ select public.create_order(
       (select jsonb_agg(jsonb_build_object('variant_id', gen_random_uuid(), 'quantity', 1))
          from generate_series(1, 21)),
       gen_random_uuid()) $$,
  '22023', 'too_many_items', 'mais de 20 peças diferentes → too_many_items'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CB-P-BRA'), 'quantity', 1)), null) $$,
  '22023', 'invalid_session', 'sem sessão → invalid_session'
);

-- Antispam: 5 pedidos por sessão por hora (a sessão de cima já tem 1).
select lives_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CB-P-BRA'), 'quantity', 1)),
       (select id from session))
     from generate_series(1, 4) $$,
  'até 5 pedidos por sessão na mesma hora'
);
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CB-P-BRA'), 'quantity', 1)),
       (select id from session)) $$,
  'P0001', 'rate_limited', '6º pedido da mesma sessão → rate_limited'
);

-- Loja fechada (A14)
reset role;
update public.store_settings set is_open = false where id = 1;
set local role anon;
select throws_ok(
  $$ select public.create_order(jsonb_build_array(jsonb_build_object(
       'variant_id', (select id from v where sku = 'CB-P-BRA'), 'quantity', 1)),
       gen_random_uuid()) $$,
  'P0001', 'store_closed', 'loja fechada → store_closed'
);
reset role;
update public.store_settings set is_open = true where id = 1;
set local role anon;

-- -----------------------------------------------------------------------------
-- get_order_public
-- -----------------------------------------------------------------------------
select is(
  (select public.get_order_public(lower(payload->>'code'))->>'code' from result),
  (select payload->>'code' from result),
  'busca por código ignora caixa'
);
select ok(
  (select public.get_order_public(payload->>'code') ? 'items' from result),
  'resumo público traz os itens'
);
select is(
  (select public.get_order_public(payload->>'code')->>'customer_name' from result),
  null,
  'resumo público NÃO expõe o nome do cliente'
);
select is(
  (select count(*)::int
     from result, jsonb_array_elements(public.get_order_public(payload->>'code')->'items') i
    where i->>'note' is not null),
  0,
  'resumo público NÃO expõe observações'
);
select is(public.get_order_public('ZZZZZZ'), null, 'código inexistente → null');

reset role;
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-00000000a0a0", "role": "authenticated"}';
select is(
  (select public.get_order_public(payload->>'code')->>'customer_name' from result),
  'Maria da Silva',
  'Ana (admin) vê o nome do cliente'
);
reset role;
set local role anon;

-- -----------------------------------------------------------------------------
-- track_visit
-- -----------------------------------------------------------------------------
select lives_ok(
  $$ select public.track_visit((select id from session), 'whatsapp', 'verao', 'l.instagram.com', '/feminino', 'mobile') $$,
  'registra a visita'
);
select lives_ok(
  $$ select public.track_visit((select id from session), 'site', null, null, '/', 'hacker') $$,
  'segunda visita da mesma sessão não dá erro (first-touch)'
);
reset role;
select is(
  (select source::text || '/' || coalesce(device_type, '-') from public.visits where session_id = (select id from session)),
  'whatsapp/mobile',
  'first-touch: a primeira origem é mantida'
);
select is(
  (select count(*)::int from public.visits where session_id = (select id from session)),
  1,
  'uma visita por sessão'
);

select * from finish();
rollback;
