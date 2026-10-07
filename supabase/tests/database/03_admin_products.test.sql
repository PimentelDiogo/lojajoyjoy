-- =============================================================================
-- PR-09 · save_product / create_category / slugify — roda com `supabase test db`
-- Papéis: anon, logado comum (sem admin) e Ana (admin do seed).
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- -----------------------------------------------------------------------------
-- Permissões
-- -----------------------------------------------------------------------------
select ok(not has_function_privilege('anon', 'public.save_product(jsonb, jsonb, jsonb)', 'execute'),
  'anon NÃO executa save_product');
select ok(has_function_privilege('authenticated', 'public.save_product(jsonb, jsonb, jsonb)', 'execute'),
  'logado executa save_product (o is_admin decide)');
select ok(not has_function_privilege('anon', 'public.create_category(text, public.gender_type)', 'execute'),
  'anon NÃO executa create_category');
select ok(not has_function_privilege('anon', 'public.slugify(text)', 'execute'),
  'anon NÃO executa slugify');
select is(
  (select prosecdef from pg_proc where oid = 'public.save_product(jsonb, jsonb, jsonb)'::regprocedure),
  false,
  'save_product é security invoker (RLS continua valendo)'
);

select is(public.slugify('  Vestido Midi Linho Rosê!! '), 'vestido-midi-linho-rose', 'slugify tira acento e símbolos');
select is(public.slugify('Calça Ção ÑAÇÃO'), 'calca-cao-nacao', 'slugify: ç, ã, ñ');

-- Foto já enviada ao bucket (o app sobe antes de chamar save_product).
insert into storage.objects (bucket_id, name)
values ('product-images', 'aaaa0000-0000-4000-a000-000000000001/capa.webp'),
       ('product-images', 'aaaa0000-0000-4000-a000-000000000001/costas.webp');

-- Pedido com a variante "P Rosa" do Vestido Midi Linho (seed), para testar
-- que variante com pedido é desativada em vez de apagada.
insert into public.orders (id, code, session_id, total)
values ('bbbb0000-0000-4000-a000-000000000001', 'TST001', gen_random_uuid(), 189.90);
insert into public.order_items (order_id, variant_id, product_name, size, color_name, unit_price, quantity)
select 'bbbb0000-0000-4000-a000-000000000001', id, 'Vestido Midi Linho', size, color_name, 189.90, 1
  from public.product_variants
 where product_id = '20000000-0000-4000-a000-000000000001' and size = 'P' and color_name = 'Rosa';

create temp table ids as
select
  (select id from public.product_variants where product_id = '20000000-0000-4000-a000-000000000001' and size = 'P' and color_name = 'Rosa') as p_rosa,
  (select id from public.product_variants where product_id = '20000000-0000-4000-a000-000000000001' and size = 'M' and color_name = 'Rosa') as m_rosa,
  (select id from public.product_variants where product_id = '20000000-0000-4000-a000-000000000001' and size = 'G' and color_name = 'Rosa') as g_rosa;
grant select on ids to anon, authenticated;

create function pg_temp.new_product(p_name text default 'Saia Plissada Rosê') returns jsonb language sql as $$
  select public.save_product(
    jsonb_build_object(
      'id', 'aaaa0000-0000-4000-a000-000000000001', 'name', p_name,
      'description', 'Saia midi.', 'gender', 'feminino', 'base_price', 159.90,
      'compare_at_price', 199.90, 'is_active', true, 'is_featured', true
    ),
    '[{"size":"P","color_name":"Rosa","color_hex":"#F4A7B9","stock":3},
      {"size":"M","color_name":"Rosa","color_hex":"#F4A7B9","stock":0}]'::jsonb,
    '["aaaa0000-0000-4000-a000-000000000001/capa.webp",
      "aaaa0000-0000-4000-a000-000000000001/costas.webp"]'::jsonb
  );
$$;
grant execute on function pg_temp.new_product(text) to anon, authenticated;

-- -----------------------------------------------------------------------------
-- Quem não é admin
-- -----------------------------------------------------------------------------
set local role anon;
select throws_ok($$ select pg_temp.new_product() $$, '42501', null, 'anon não salva produto');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-0000000000ff", "role": "authenticated"}';
select throws_ok($$ select pg_temp.new_product() $$, 'forbidden', 'logado sem admin não salva produto');
select throws_ok($$ select public.create_category('Saias', 'feminino') $$, 'forbidden', 'logado sem admin não cria categoria');
reset role;

-- -----------------------------------------------------------------------------
-- Ana (admin)
-- -----------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-00000000a0a0", "role": "authenticated"}';

select is(pg_temp.new_product() ->> 'slug', 'saia-plissada-rose', 'cria a peça e devolve o slug');
select is(
  (select count(*)::int from public.product_variants where product_id = 'aaaa0000-0000-4000-a000-000000000001'),
  2, 'criou as 2 variantes'
);
select is(
  (select storage_path from public.product_images where product_id = 'aaaa0000-0000-4000-a000-000000000001' and position = 0),
  'aaaa0000-0000-4000-a000-000000000001/capa.webp', 'primeira foto é a capa'
);

-- Renomear não muda o slug (links já enviados continuam valendo).
select is(pg_temp.new_product('Saia Plissada Nova') ->> 'slug', 'saia-plissada-rose', 'editar não muda o slug');

-- Reordenar fotos: costas vira capa.
select lives_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 159.90),
    '[{"size":"P","color_name":"Rosa","stock":3}]'::jsonb,
    '["aaaa0000-0000-4000-a000-000000000001/costas.webp", "aaaa0000-0000-4000-a000-000000000001/capa.webp"]'::jsonb)
$$, 'reordena fotos e remove variante sem pedido');
select is(
  (select storage_path from public.product_images where product_id = 'aaaa0000-0000-4000-a000-000000000001' and position = 0),
  'aaaa0000-0000-4000-a000-000000000001/costas.webp', 'nova capa'
);
select is(
  (select count(*)::int from public.product_variants where product_id = 'aaaa0000-0000-4000-a000-000000000001'),
  1, 'variante sem pedido que saiu do formulário foi apagada'
);

-- Segundo produto com o mesmo nome ganha slug com sufixo.
insert into storage.objects (bucket_id, name) values ('product-images', 'aaaa0000-0000-4000-a000-000000000002/a.jpg');
select is(
  public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000002', 'name', 'Saia Plissada Rosê', 'gender', 'feminino', 'base_price', 99),
    '[{"size":"U","color_name":"Preto","stock":1}]'::jsonb,
    '["aaaa0000-0000-4000-a000-000000000002/a.jpg"]'::jsonb) ->> 'slug',
  'saia-plissada-rose-2', 'slug repetido ganha sufixo'
);

-- Fotos: só do próprio produto, existentes e no formato esperado.
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    '[{"size":"P","color_name":"Rosa","stock":1}]'::jsonb,
    '["aaaa0000-0000-4000-a000-000000000002/a.jpg"]'::jsonb)
$$, 'invalid_image', 'não aceita foto de outro produto');
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    '[{"size":"P","color_name":"Rosa","stock":1}]'::jsonb,
    '["aaaa0000-0000-4000-a000-000000000001/../x.jpg"]'::jsonb)
$$, 'invalid_image', 'não aceita caminho com ..');
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    '[{"size":"P","color_name":"Rosa","stock":1}]'::jsonb,
    '["aaaa0000-0000-4000-a000-000000000001/nao-enviada.webp"]'::jsonb)
$$, 'image_not_found', 'foto precisa existir no bucket');

-- Validações das variantes.
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    '[{"size":"P","color_name":"Rosa","stock":1}, {"size":"p","color_name":" rosa","stock":2}]'::jsonb, '[]'::jsonb)
$$, 'duplicate_variant', 'tamanho × cor repetido');
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    '[{"size":"P","color_name":"Rosa","stock":-1}]'::jsonb, '[]'::jsonb)
$$, 'invalid_stock', 'estoque negativo');
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    '[]'::jsonb, '[]'::jsonb)
$$, 'invalid_variants', 'precisa de ao menos uma variante');
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10),
    jsonb_build_array(jsonb_build_object('id', (select m_rosa from ids), 'size', 'M', 'color_name', 'Rosa', 'stock', 1)),
    '[]'::jsonb)
$$, 'invalid_variant', 'não edita variante de outro produto');
select throws_ok($$
  select public.save_product(
    jsonb_build_object('id', 'aaaa0000-0000-4000-a000-000000000001', 'name', 'Saia', 'gender', 'feminino', 'base_price', 10, 'compare_at_price', 5),
    '[{"size":"P","color_name":"Rosa","stock":1}]'::jsonb, '[]'::jsonb)
$$, '23514', null, 'preço "de" menor que o preço é recusado');

-- Estoque por diferença: Ana abriu com M Rosa = 1 e quer 5.
reset role;
update public.product_variants set stock_qty = 0 where id = (select m_rosa from ids); -- vendeu 1 enquanto ela editava
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-00000000a0a0", "role": "authenticated"}';
select lives_ok($$
  select public.save_product(
    jsonb_build_object('id', '20000000-0000-4000-a000-000000000001', 'name', 'Vestido Midi Linho', 'gender', 'feminino', 'base_price', 189.90),
    jsonb_build_array(
      jsonb_build_object('id', (select m_rosa from ids), 'size', 'M', 'color_name', 'Rosa', 'color_hex', '#F4A7B9', 'stock', 5, 'base_stock', 1),
      jsonb_build_object('id', (select g_rosa from ids), 'size', 'G', 'color_name', 'Rosa', 'color_hex', '#F4A7B9', 'stock', 2, 'base_stock', 0)
    ),
    '[]'::jsonb)
$$, 'edita o Vestido tirando P Rosa (que tem pedido) e a cor Areia');
select is((select stock_qty from public.product_variants where id = (select m_rosa from ids)), 4,
  'estoque por diferença: 0 atual + (5 − 1) = 4 (a venda não se perde)');
select is((select stock_qty from public.product_variants where id = (select g_rosa from ids)), 2, 'G Rosa = 2');
select is((select is_active from public.product_variants where id = (select p_rosa from ids)), false,
  'P Rosa tem pedido → desativada, não apagada');
select is(
  (select count(*)::int from public.product_variants where product_id = '20000000-0000-4000-a000-000000000001' and color_name = 'Areia'),
  0, 'M Areia sem pedido → apagada'
);

-- Readicionar P Rosa reativa a variante antiga (o pedido continua apontando para ela).
select lives_ok($$
  select public.save_product(
    jsonb_build_object('id', '20000000-0000-4000-a000-000000000001', 'name', 'Vestido Midi Linho', 'gender', 'feminino', 'base_price', 189.90),
    jsonb_build_array(
      jsonb_build_object('id', (select m_rosa from ids), 'size', 'M', 'color_name', 'Rosa', 'stock', 4, 'base_stock', 4),
      jsonb_build_object('size', 'P', 'color_name', 'Rosa', 'stock', 7)
    ),
    '[]'::jsonb)
$$, 'readiciona P Rosa');
select is(
  (select is_active::text || '/' || stock_qty from public.product_variants where id = (select p_rosa from ids)),
  'true/7', 'P Rosa reativada com o novo estoque'
);

-- Categoria nova direto do formulário.
select is(public.create_category('  Saias  Longas ', 'feminino') ->> 'slug', 'saias-longas', 'cria categoria');
select is(
  public.create_category('saias longas', 'feminino') ->> 'slug', 'saias-longas',
  'mesmo nome na mesma seção reaproveita a categoria'
);
select throws_ok($$ select public.create_category('   ', 'feminino') $$, 'invalid_category', 'nome vazio');
reset role;

-- O público só vê o que está ativo.
set local role anon;
select is(
  (select count(*)::int from public.product_variants where id = (select p_rosa from ids)),
  1, 'anon vê a variante reativada'
);
reset role;

select * from finish();
rollback;
