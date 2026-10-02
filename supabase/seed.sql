-- =============================================================================
-- SEED LOCAL — DADOS FICTÍCIOS (MOCK)
--
-- Motivo do mock: desenvolver e testar a vitrine, o carrinho e os relatórios
-- antes de a Ana cadastrar as peças reais.
--
-- ⚠️  Roda SÓ no ambiente local (`supabase db reset`). NUNCA na nuvem:
--     `supabase db push` aplica apenas as migrations, não este arquivo.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Admin local: ana@joyjoy.com.br / senha provisória de desenvolvimento.
-- Na nuvem (PR-11) a usuária será criada com OUTRA senha, forte.
-- -----------------------------------------------------------------------------
do $$
declare
  v_ana uuid := '00000000-0000-4000-a000-00000000a0a0';
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  ) values (
    '00000000-0000-0000-0000-000000000000', v_ana, 'authenticated', 'authenticated',
    'ana@joyjoy.com.br', extensions.crypt('joy123', extensions.gen_salt('bf')),
    now(), '{"provider":"email","providers":["email"]}', '{"name":"Ana"}',
    now(), now(),
    '', '', '', ''
  );

  insert into auth.identities (
    id, user_id, provider_id, provider, identity_data,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_ana, v_ana::text, 'email',
    jsonb_build_object('sub', v_ana::text, 'email', 'ana@joyjoy.com.br', 'email_verified', true),
    now(), now(), now()
  );

  insert into public.admin_users (user_id) values (v_ana);
end;
$$;

-- -----------------------------------------------------------------------------
-- Recado da loja (A2) — exemplo
-- -----------------------------------------------------------------------------
update public.store_settings
   set announcement = 'Entregas em Recife e região metropolitana. Pix, cartão ou dinheiro na entrega.'
 where id = 1;

-- -----------------------------------------------------------------------------
-- Categorias
-- -----------------------------------------------------------------------------
insert into public.categories (id, name, slug, gender, position) values
  ('10000000-0000-4000-a000-000000000001', 'Vestidos',  'vestidos',  'feminino',  1),
  ('10000000-0000-4000-a000-000000000002', 'Blusas',    'blusas',    'feminino',  2),
  ('10000000-0000-4000-a000-000000000003', 'Camisas',   'camisas',   'masculino', 3),
  ('10000000-0000-4000-a000-000000000004', 'Bermudas',  'bermudas',  'masculino', 4),
  ('10000000-0000-4000-a000-000000000005', 'Camisetas', 'camisetas', 'unissex',   5),
  ('10000000-0000-4000-a000-000000000006', 'Calças',    'calcas',    'unissex',   6);

-- -----------------------------------------------------------------------------
-- Produtos
-- -----------------------------------------------------------------------------
insert into public.products
  (id, category_id, name, slug, description, gender, base_price, compare_at_price, is_featured, is_active)
values
  ('20000000-0000-4000-a000-000000000001', '10000000-0000-4000-a000-000000000001',
   'Vestido Midi Linho', 'vestido-midi-linho',
   'Linho leve com caimento fluido. Perfeito para o verão de Recife.',
   'feminino', 189.90, null, true, true),
  ('20000000-0000-4000-a000-000000000002', '10000000-0000-4000-a000-000000000001',
   'Vestido Tule Alcinha', 'vestido-tule-alcinha',
   'Tule com forro, alcinhas reguláveis.',
   'feminino', 98.00, 129.90, false, true),
  ('20000000-0000-4000-a000-000000000003', '10000000-0000-4000-a000-000000000002',
   'Blusa Cropped Canelada', 'blusa-cropped-canelada',
   'Malha canelada com elastano.',
   'feminino', 59.90, null, true, true),
  ('20000000-0000-4000-a000-000000000004', '10000000-0000-4000-a000-000000000003',
   'Camisa Oxford', 'camisa-oxford',
   'Algodão oxford, manga longa, corte slim.',
   'masculino', 129.90, 159.90, true, true),
  ('20000000-0000-4000-a000-000000000005', '10000000-0000-4000-a000-000000000004',
   'Bermuda Sarja', 'bermuda-sarja',
   'Sarja com elastano, cinco bolsos.',
   'masculino', 99.90, null, false, true),
  ('20000000-0000-4000-a000-000000000006', '10000000-0000-4000-a000-000000000005',
   'Camiseta Básica Algodão', 'camiseta-basica-algodao',
   'Algodão penteado 30.1. Unissex.',
   'unissex', 49.90, null, false, true),
  ('20000000-0000-4000-a000-000000000007', '10000000-0000-4000-a000-000000000006',
   'Calça Wide Leg', 'calca-wide-leg',
   'Alfaiataria com cintura alta.',
   'feminino', 149.90, null, false, true),
  -- Inativo: serve para testar que NÃO aparece na vitrine.
  ('20000000-0000-4000-a000-000000000008', '10000000-0000-4000-a000-000000000003',
   'Camisa Linho (coleção passada)', 'camisa-linho-colecao-passada',
   'Fora de linha.',
   'masculino', 139.90, null, false, false);

-- -----------------------------------------------------------------------------
-- Variantes (tamanho × cor × estoque)
-- -----------------------------------------------------------------------------
insert into public.product_variants (product_id, size, color_name, color_hex, sku, stock_qty) values
  -- Vestido Midi Linho
  ('20000000-0000-4000-a000-000000000001', 'P', 'Rosa',  '#F4A7B9', 'VML-P-ROS', 3),
  ('20000000-0000-4000-a000-000000000001', 'M', 'Rosa',  '#F4A7B9', 'VML-M-ROS', 1), -- últimas unidades
  ('20000000-0000-4000-a000-000000000001', 'G', 'Rosa',  '#F4A7B9', 'VML-G-ROS', 0), -- esgotado
  ('20000000-0000-4000-a000-000000000001', 'M', 'Areia', '#D8C3A5', 'VML-M-ARE', 4),
  -- Vestido Tule Alcinha
  ('20000000-0000-4000-a000-000000000002', 'P', 'Preto', '#1F1F1F', 'VTA-P-PRE', 2),
  ('20000000-0000-4000-a000-000000000002', 'M', 'Preto', '#1F1F1F', 'VTA-M-PRE', 2),
  -- Blusa Cropped
  ('20000000-0000-4000-a000-000000000003', 'U', 'Off-white', '#F5F0E6', 'BCC-U-OFF', 6),
  ('20000000-0000-4000-a000-000000000003', 'U', 'Terracota', '#B04E1C', 'BCC-U-TER', 5),
  -- Camisa Oxford
  ('20000000-0000-4000-a000-000000000004', 'M',  'Azul',   '#7FA7D4', 'CO-M-AZU', 3),
  ('20000000-0000-4000-a000-000000000004', 'G',  'Azul',   '#7FA7D4', 'CO-G-AZU', 2),
  ('20000000-0000-4000-a000-000000000004', 'GG', 'Branca', '#FFFFFF', 'CO-GG-BRA', 1),
  -- Bermuda Sarja
  ('20000000-0000-4000-a000-000000000005', '40', 'Caqui', '#B9A27A', 'BS-40-CAQ', 4),
  ('20000000-0000-4000-a000-000000000005', '42', 'Caqui', '#B9A27A', 'BS-42-CAQ', 3),
  ('20000000-0000-4000-a000-000000000005', '44', 'Caqui', '#B9A27A', 'BS-44-CAQ', 0),
  -- Camiseta Básica
  ('20000000-0000-4000-a000-000000000006', 'P', 'Branca', '#FFFFFF', 'CB-P-BRA', 10),
  ('20000000-0000-4000-a000-000000000006', 'M', 'Branca', '#FFFFFF', 'CB-M-BRA', 8),
  ('20000000-0000-4000-a000-000000000006', 'M', 'Preta',  '#1F1F1F', 'CB-M-PRE', 7),
  -- Calça Wide Leg
  ('20000000-0000-4000-a000-000000000007', '38', 'Bege', '#D8C3A5', 'CWL-38-BEG', 2),
  ('20000000-0000-4000-a000-000000000007', '40', 'Bege', '#D8C3A5', 'CWL-40-BEG', 2),
  -- Produto inativo
  ('20000000-0000-4000-a000-000000000008', 'M', 'Verde', '#8FBF9F', 'CL-M-VER', 5);

-- Imagens: entram quando a Ana cadastrar pelo admin (PR-09). A vitrine (PR-04)
-- mostra um placeholder para produtos sem foto.
