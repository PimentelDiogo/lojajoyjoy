-- =============================================================================
-- ADR-0014 · Modo de auditoria de estoque
--
-- Reaproveita `is_open` (já bloqueia o checkout, ver ADR-0006/cart) — só
-- acrescenta `stock_audit_ends_at`: horário absoluto (calculado aqui no
-- banco, não no cliente) até quando a Ana previu terminar a auditoria.
-- Não reabre a loja sozinha quando o prazo passa: só `stop_stock_audit`
-- (chamado pela Ana) desliga o modo.
-- =============================================================================

alter table public.store_settings
  add column stock_audit_ends_at timestamptz;

comment on column public.store_settings.stock_audit_ends_at is
  'ADR-0014: horário previsto pra Ana terminar a auditoria de estoque. '
  'null = não está em auditoria. Não reabre a loja sozinha quando passa.';

-- -----------------------------------------------------------------------------
-- start_stock_audit: fecha a loja com prazo (15, 30 ou 60 min)
-- -----------------------------------------------------------------------------
create or replace function public.start_stock_audit(p_minutes int)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.store_settings;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_minutes not in (15, 30, 60) then
    raise exception 'invalid_minutes' using errcode = '22023';
  end if;

  update public.store_settings
     set is_open = false,
         stock_audit_ends_at = now() + make_interval(mins => p_minutes)
   where id = 1
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

comment on function public.start_stock_audit(int) is
  'ADR-0014: fecha a loja por um prazo fixo (15/30/60 min); horário de término calculado no banco.';

-- -----------------------------------------------------------------------------
-- stop_stock_audit: reabre a loja (sempre manual, nunca automático)
-- -----------------------------------------------------------------------------
create or replace function public.stop_stock_audit()
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.store_settings;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;

  update public.store_settings
     set is_open = true,
         stock_audit_ends_at = null
   where id = 1
  returning * into v_row;

  return to_jsonb(v_row);
end;
$$;

comment on function public.stop_stock_audit() is
  'ADR-0014: reabre a loja e limpa o prazo da auditoria.';

revoke execute on function public.start_stock_audit(int) from public, anon;
revoke execute on function public.stop_stock_audit() from public, anon;

grant execute on function public.start_stock_audit(int) to authenticated;
grant execute on function public.stop_stock_audit() to authenticated;
