-- =============================================================================
-- Dados do rodapé da loja (Instagram, endereço de retirada, formas de pagamento)
-- Ficam em store_settings para a Ana editar no admin — nada fixo no código.
-- =============================================================================

alter table public.store_settings
  add column instagram_handle text
    check (instagram_handle ~ '^[A-Za-z0-9._]{1,30}$'),
  add column pickup_address text
    check (length(pickup_address) <= 200),
  add column payment_methods public.payment_method[] not null
    default array['card', 'pix']::public.payment_method[];

comment on column public.store_settings.instagram_handle is 'Perfil sem @ (ex.: joyjoybrand_).';
comment on column public.store_settings.pickup_address is 'Endereço para retirada exibido no rodapé.';
comment on column public.store_settings.payment_methods is 'Formas de pagamento aceitas (rodapé).';

-- Configuração real da loja (enviada pela Ana em 2026-10-07).
update public.store_settings
   set instagram_handle = 'joyjoybrand_',
       pickup_address   = 'Rua Professor Júlio Ferreira de Melo, 355 - Boa Viagem, Recife - PE',
       payment_methods  = array['card', 'pix']::public.payment_method[]
 where id = 1;
