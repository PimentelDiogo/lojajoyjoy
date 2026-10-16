-- =============================================================================
-- ADR-0014 · start_stock_audit / stop_stock_audit — roda com `supabase test db`
-- =============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select * from no_plan();

select ok(not has_function_privilege('anon', 'public.start_stock_audit(int)', 'execute'), 'anon NÃO executa start_stock_audit');
select ok(not has_function_privilege('anon', 'public.stop_stock_audit()', 'execute'), 'anon NÃO executa stop_stock_audit');
select ok(has_function_privilege('authenticated', 'public.start_stock_audit(int)', 'execute'), 'logado executa start_stock_audit (o is_admin decide)');

-- Estado inicial: loja aberta, sem auditoria (seed).
select is((select is_open from public.store_settings where id = 1), true, 'seed: loja começa aberta');
select is((select stock_audit_ends_at from public.store_settings where id = 1), null, 'seed: sem auditoria');

-- -----------------------------------------------------------------------------
-- Quem não é admin
-- -----------------------------------------------------------------------------
set local role anon;
select throws_ok($$ select public.start_stock_audit(15) $$, '42501', null, 'anon não inicia auditoria');
reset role;

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-0000000000ff", "role": "authenticated"}';
select throws_ok($$ select public.start_stock_audit(15) $$, 'forbidden', 'logado sem admin não inicia auditoria');
select throws_ok($$ select public.stop_stock_audit() $$, 'forbidden', 'logado sem admin não para a auditoria');
reset role;

-- -----------------------------------------------------------------------------
-- Ana
-- -----------------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-4000-a000-00000000a0a0", "role": "authenticated"}';

select throws_ok($$ select public.start_stock_audit(45) $$, 'invalid_minutes', 'só aceita 15, 30 ou 60');

select is((public.start_stock_audit(30) ->> 'is_open')::boolean, false, 'start_stock_audit fecha a loja');
select ok(
  (select stock_audit_ends_at from public.store_settings where id = 1)
    between now() + interval '29 minutes' and now() + interval '31 minutes',
  'prazo calculado no banco (~30 min a partir de agora)'
);

select is((public.stop_stock_audit() ->> 'is_open')::boolean, true, 'stop_stock_audit reabre a loja');
select is((select stock_audit_ends_at from public.store_settings where id = 1), null, 'stop_stock_audit limpa o prazo');

reset role;

-- Visitante (anon) continua lendo store_settings normalmente (select já era público).
set local request.jwt.claims = '{"role": "anon"}';
set local role anon;
select is((select is_open from public.store_settings where id = 1), true, 'anon lê a loja aberta de novo');
reset role;

select * from finish();
rollback;
