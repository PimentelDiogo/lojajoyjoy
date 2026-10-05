-- =============================================================================
-- RLS e regras do catálogo (PR-03) — roda com `supabase test db`
--
-- Papéis testados:
--   anon           → visitante da vitrine (anon key pública)
--   authenticated  → pessoa logada que NÃO é admin
--   admin          → Ana (seed: 00000000-0000-4000-a000-00000000a0a0)
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

-- -----------------------------------------------------------------------------
-- Estrutura e constraints
-- -----------------------------------------------------------------------------
select is(
  (select count(*)::int from pg_tables where schemaname = 'public' and not rowsecurity),
  0,
  'RLS ligado em TODAS as tabelas do schema public'
);

select ok(
  exists (select 1 from public.admin_users where user_id = '00000000-0000-4000-a000-00000000a0a0'),
  'seed: Ana é admin'
);

select is(
  (select whatsapp_number from public.store_settings where id = 1),
  '5581986323686',
  'store_settings tem o WhatsApp da Ana'
);

select throws_ok(
  $$ insert into public.store_settings (id, whatsapp_number) values (2, '5581986323686') $$,
  '23514', null,
  'store_settings aceita só a linha id = 1'
);

select throws_ok(
  $$ update public.store_settings set whatsapp_number = '81 98632-3686' where id = 1 $$,
  '23514', null,
  'WhatsApp precisa estar no formato wa.me (só dígitos, com DDI)'
);

select throws_ok(
  $$ insert into public.product_variants (product_id, size, color_name, stock_qty)
     values ('20000000-0000-4000-a000-000000000001', 'PP', 'Rosa', -1) $$,
  '23514', null,
  'estoque nunca negativo'
);

select throws_ok(
  $$ insert into public.products (name, slug, gender, base_price, compare_at_price)
     values ('Teste', 'teste-preco', 'unissex', 100, 90) $$,
  '23514', null,
  'preço riscado precisa ser maior que o preço'
);

select throws_ok(
  $$ insert into public.product_variants (product_id, size, color_name)
     values ('20000000-0000-4000-a000-000000000001', 'P', 'Rosa') $$,
  '23505', null,
  'variante tamanho × cor é única por produto'
);

select throws_ok(
  $$ insert into public.product_images (product_id, storage_path)
     values ('20000000-0000-4000-a000-000000000001', '../../segredo.jpg') $$,
  '23514', null,
  'storage_path não aceita path traversal'
);

select is(
  (select count(*)::int
     from information_schema.role_table_grants
    where table_schema = 'public'
      and grantee in ('anon', 'authenticated')
      and privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')),
  0,
  'anon/authenticated sem TRUNCATE/TRIGGER/REFERENCES nas tabelas públicas'
);

-- -----------------------------------------------------------------------------
-- anon (visitante)
-- -----------------------------------------------------------------------------
set local role anon;

select is((select public.is_admin()), false, 'anon: não é admin');

select is(
  (select count(*)::int from public.products), 7,
  'anon: vê os 7 produtos ativos'
);
select is(
  (select count(*)::int from public.products where not is_active), 0,
  'anon: não vê produto inativo'
);
select is(
  (select count(*)::int from public.product_variants
    where product_id = '20000000-0000-4000-a000-000000000008'), 0,
  'anon: não vê variantes de produto inativo'
);
select is(
  (select whatsapp_number from public.store_settings), '5581986323686',
  'anon: lê a configuração pública da loja'
);
select is(
  (select count(*)::int from public.admin_users), 0,
  'anon: não enxerga admin_users'
);

select throws_ok(
  $$ insert into public.products (name, slug, gender, base_price)
     values ('Hack', 'hack', 'unissex', 1) $$,
  '42501', null,
  'anon: não cria produto'
);
select throws_ok(
  $$ insert into public.categories (name, slug) values ('Hack', 'hack') $$,
  '42501', null,
  'anon: não cria categoria'
);
select lives_ok(
  $$ update public.products set base_price = 1 $$,
  'anon: UPDATE não dá erro, mas não afeta linhas (verificado no fim)'
);
select lives_ok(
  $$ update public.store_settings set whatsapp_number = '5500000000000' $$,
  'anon: tentativa de trocar o WhatsApp não dá erro (verificado no fim)'
);
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('product-images', 'hack.jpg') $$,
  '42501', null,
  'anon: não envia imagem para o storage'
);

reset role;

-- -----------------------------------------------------------------------------
-- authenticated NÃO admin (ex.: alguém que conseguiu uma conta)
-- -----------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-0000000000b0", "role": "authenticated"}';

select is((select public.is_admin()), false, 'logado comum: não é admin');
select is(
  (select count(*)::int from public.products where not is_active), 0,
  'logado comum: não vê produto inativo'
);
select throws_ok(
  $$ insert into public.products (name, slug, gender, base_price)
     values ('Hack', 'hack-2', 'unissex', 1) $$,
  '42501', null,
  'logado comum: não cria produto'
);
select throws_ok(
  $$ insert into public.admin_users (user_id) values ('00000000-0000-4000-a000-0000000000b0') $$,
  '42501', null,
  'logado comum: não se promove a admin'
);
select throws_ok(
  $$ insert into storage.objects (bucket_id, name) values ('product-images', 'hack-2.jpg') $$,
  '42501', null,
  'logado comum: não envia imagem'
);

reset role;

-- -----------------------------------------------------------------------------
-- admin (Ana)
-- -----------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-00000000a0a0", "role": "authenticated"}';

select is((select public.is_admin()), true, 'Ana: é admin');
select is(
  (select count(*)::int from public.products), 8,
  'Ana: vê também os produtos inativos'
);
select is(
  (select count(*)::int from public.admin_users), 1,
  'Ana: vê o próprio registro em admin_users'
);
select lives_ok(
  $$ insert into public.products (name, slug, gender, base_price)
     values ('Saia Midi', 'saia-midi', 'feminino', 119.90) $$,
  'Ana: cria produto'
);
select lives_ok(
  $$ update public.store_settings set announcement = 'Promoção de verão!' where id = 1 $$,
  'Ana: altera o recado da loja'
);
select lives_ok(
  $$ insert into storage.objects (bucket_id, name) values ('product-images', 'teste/foto.jpg') $$,
  'Ana: envia imagem para o bucket product-images'
);
select throws_ok(
  $$ insert into public.admin_users (user_id) values ('00000000-0000-4000-a000-0000000000b0') $$,
  '42501', null,
  'Ana: nem admin cria outra admin pela API (só via SQL/Studio)'
);

reset role;

-- -----------------------------------------------------------------------------
-- Efeitos das tentativas anônimas
-- -----------------------------------------------------------------------------
select is(
  (select whatsapp_number from public.store_settings where id = 1),
  '5581986323686',
  'UPDATE anônimo NÃO alterou o WhatsApp'
);
select is(
  (select count(*)::int from public.products where base_price = 1), 0,
  'UPDATE anônimo NÃO alterou preços'
);

select * from finish();
rollback;
