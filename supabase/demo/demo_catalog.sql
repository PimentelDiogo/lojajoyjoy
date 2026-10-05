-- =============================================================================
-- CATÁLOGO DE DEMONSTRAÇÃO (3 femininas + 3 masculinas)
--
-- Motivo do mock: a Ana validar o escopo e as funcionalidades da vitrine
-- (destaques, preço riscado, "Últimas unidades", esgotado + "Avise-me",
-- várias cores e tamanhos) antes do cadastro real (PR-09).
--
-- Rodar:    supabase db query --linked -f supabase/demo/demo_catalog.sql
-- Remover:  supabase db query --linked -f supabase/demo/remove_demo_catalog.sql
--
-- Idempotente: IDs fixos com o marcador "dede" (de-mo) — rodar de novo atualiza.
-- Não é migration de propósito: não deve existir no schema da loja.
-- =============================================================================

-- Categorias ---------------------------------------------------------------
insert into public.categories (id, name, slug, gender, position) values
  ('dede0000-0000-4000-a000-0000000000c1', 'Vestidos', 'vestidos', 'feminino', 1),
  ('dede0000-0000-4000-a000-0000000000c2', 'Blusas',   'blusas',   'feminino', 2),
  ('dede0000-0000-4000-a000-0000000000c3', 'Calças',   'calcas',   'feminino', 3),
  ('dede0000-0000-4000-a000-0000000000c4', 'Camisas',  'camisas',  'masculino', 4),
  ('dede0000-0000-4000-a000-0000000000c5', 'Bermudas', 'bermudas', 'masculino', 5),
  ('dede0000-0000-4000-a000-0000000000c6', 'Polos',    'polos',    'masculino', 6)
on conflict (id) do update set
  name = excluded.name, slug = excluded.slug, gender = excluded.gender,
  position = excluded.position, is_active = true;

-- Produtos -----------------------------------------------------------------
insert into public.products
  (id, category_id, name, slug, description, gender, base_price, compare_at_price, is_featured)
values
  -- FEMININO
  ('dede0000-0000-4000-a000-000000000001', 'dede0000-0000-4000-a000-0000000000c1',
   'Vestido Midi Linho', 'vestido-midi-linho',
   'Linho leve com caimento fluido e alças finas. Perfeito para o verão de Recife.',
   'feminino', 189.90, null, true),
  ('dede0000-0000-4000-a000-000000000002', 'dede0000-0000-4000-a000-0000000000c2',
   'Blusa Cropped Canelada', 'blusa-cropped-canelada',
   'Malha canelada com elastano, veste do P ao M. Combina com calça de cintura alta.',
   'feminino', 59.90, 79.90, true),
  ('dede0000-0000-4000-a000-000000000003', 'dede0000-0000-4000-a000-0000000000c3',
   'Calça Wide Leg Alfaiataria', 'calca-wide-leg-alfaiataria',
   'Alfaiataria com cintura alta, pernas amplas e bolsos faca.',
   'feminino', 149.90, null, false),
  -- MASCULINO
  ('dede0000-0000-4000-a000-000000000004', 'dede0000-0000-4000-a000-0000000000c4',
   'Camisa Oxford Manga Longa', 'camisa-oxford-manga-longa',
   'Algodão oxford, corte slim e botões de madrepérola.',
   'masculino', 129.90, 159.90, true),
  ('dede0000-0000-4000-a000-000000000005', 'dede0000-0000-4000-a000-0000000000c5',
   'Bermuda Sarja', 'bermuda-sarja',
   'Sarja com elastano, cinco bolsos e barra italiana.',
   'masculino', 99.90, null, false),
  ('dede0000-0000-4000-a000-000000000006', 'dede0000-0000-4000-a000-0000000000c6',
   'Polo Piquet', 'polo-piquet',
   'Piquet de algodão com gola e punhos canelados.',
   'masculino', 89.90, null, false)
on conflict (id) do update set
  category_id = excluded.category_id, name = excluded.name, slug = excluded.slug,
  description = excluded.description, gender = excluded.gender,
  base_price = excluded.base_price, compare_at_price = excluded.compare_at_price,
  is_featured = excluded.is_featured, is_active = true;

-- Variantes (tamanho × cor × estoque) ---------------------------------------
-- Estoque pensado para mostrar os selos: 0 = esgotado, 1–2 = últimas unidades.
insert into public.product_variants (id, product_id, size, color_name, color_hex, sku, stock_qty) values
  -- Vestido Midi Linho: G esgotado (Avise-me), M última unidade
  ('dede0000-0000-4000-b000-000000000101', 'dede0000-0000-4000-a000-000000000001', 'P', 'Rosa',  '#F4A7B9', 'DEMO-VML-P-ROS', 3),
  ('dede0000-0000-4000-b000-000000000102', 'dede0000-0000-4000-a000-000000000001', 'M', 'Rosa',  '#F4A7B9', 'DEMO-VML-M-ROS', 1),
  ('dede0000-0000-4000-b000-000000000103', 'dede0000-0000-4000-a000-000000000001', 'G', 'Rosa',  '#F4A7B9', 'DEMO-VML-G-ROS', 0),
  ('dede0000-0000-4000-b000-000000000104', 'dede0000-0000-4000-a000-000000000001', 'M', 'Areia', '#D8C3A5', 'DEMO-VML-M-ARE', 4),
  ('dede0000-0000-4000-b000-000000000105', 'dede0000-0000-4000-a000-000000000001', 'G', 'Areia', '#D8C3A5', 'DEMO-VML-G-ARE', 2),
  -- Blusa Cropped: tamanho único, 3 cores, promoção
  ('dede0000-0000-4000-b000-000000000201', 'dede0000-0000-4000-a000-000000000002', 'U', 'Off-white', '#F5F0E6', 'DEMO-BCC-U-OFF', 6),
  ('dede0000-0000-4000-b000-000000000202', 'dede0000-0000-4000-a000-000000000002', 'U', 'Terracota', '#B04E1C', 'DEMO-BCC-U-TER', 5),
  ('dede0000-0000-4000-b000-000000000203', 'dede0000-0000-4000-a000-000000000002', 'U', 'Preto',     '#1F1F1F', 'DEMO-BCC-U-PRE', 2),
  -- Calça Wide Leg: numeração, 42 esgotado
  ('dede0000-0000-4000-b000-000000000301', 'dede0000-0000-4000-a000-000000000003', '36', 'Bege', '#D8C3A5', 'DEMO-CWL-36-BEG', 2),
  ('dede0000-0000-4000-b000-000000000302', 'dede0000-0000-4000-a000-000000000003', '38', 'Bege', '#D8C3A5', 'DEMO-CWL-38-BEG', 3),
  ('dede0000-0000-4000-b000-000000000303', 'dede0000-0000-4000-a000-000000000003', '40', 'Bege', '#D8C3A5', 'DEMO-CWL-40-BEG', 3),
  ('dede0000-0000-4000-b000-000000000304', 'dede0000-0000-4000-a000-000000000003', '42', 'Bege', '#D8C3A5', 'DEMO-CWL-42-BEG', 0),
  -- Camisa Oxford: promoção, GG branca última unidade
  ('dede0000-0000-4000-b000-000000000401', 'dede0000-0000-4000-a000-000000000004', 'M',  'Azul',   '#7FA7D4', 'DEMO-COX-M-AZU', 3),
  ('dede0000-0000-4000-b000-000000000402', 'dede0000-0000-4000-a000-000000000004', 'G',  'Azul',   '#7FA7D4', 'DEMO-COX-G-AZU', 2),
  ('dede0000-0000-4000-b000-000000000403', 'dede0000-0000-4000-a000-000000000004', 'M',  'Branca', '#FFFFFF', 'DEMO-COX-M-BRA', 4),
  ('dede0000-0000-4000-b000-000000000404', 'dede0000-0000-4000-a000-000000000004', 'GG', 'Branca', '#FFFFFF', 'DEMO-COX-GG-BRA', 1),
  -- Bermuda Sarja: 44 esgotado
  ('dede0000-0000-4000-b000-000000000501', 'dede0000-0000-4000-a000-000000000005', '38', 'Caqui',    '#B9A27A', 'DEMO-BSA-38-CAQ', 4),
  ('dede0000-0000-4000-b000-000000000502', 'dede0000-0000-4000-a000-000000000005', '40', 'Caqui',    '#B9A27A', 'DEMO-BSA-40-CAQ', 3),
  ('dede0000-0000-4000-b000-000000000503', 'dede0000-0000-4000-a000-000000000005', '42', 'Caqui',    '#B9A27A', 'DEMO-BSA-42-CAQ', 2),
  ('dede0000-0000-4000-b000-000000000504', 'dede0000-0000-4000-a000-000000000005', '44', 'Caqui',    '#B9A27A', 'DEMO-BSA-44-CAQ', 0),
  ('dede0000-0000-4000-b000-000000000505', 'dede0000-0000-4000-a000-000000000005', '40', 'Azul-marinho', '#2E3A59', 'DEMO-BSA-40-MAR', 3),
  -- Polo Piquet: 2 cores, estoque normal
  ('dede0000-0000-4000-b000-000000000601', 'dede0000-0000-4000-a000-000000000006', 'P', 'Verde', '#8FBF9F', 'DEMO-PPQ-P-VER', 5),
  ('dede0000-0000-4000-b000-000000000602', 'dede0000-0000-4000-a000-000000000006', 'M', 'Verde', '#8FBF9F', 'DEMO-PPQ-M-VER', 5),
  ('dede0000-0000-4000-b000-000000000603', 'dede0000-0000-4000-a000-000000000006', 'G', 'Verde', '#8FBF9F', 'DEMO-PPQ-G-VER', 4),
  ('dede0000-0000-4000-b000-000000000604', 'dede0000-0000-4000-a000-000000000006', 'M', 'Branca', '#FFFFFF', 'DEMO-PPQ-M-BRA', 6),
  ('dede0000-0000-4000-b000-000000000605', 'dede0000-0000-4000-a000-000000000006', 'G', 'Branca', '#FFFFFF', 'DEMO-PPQ-G-BRA', 6)
on conflict (id) do update set
  size = excluded.size, color_name = excluded.color_name, color_hex = excluded.color_hex,
  sku = excluded.sku, stock_qty = excluded.stock_qty, is_active = true;

-- Recado da loja (A2) — para a Ana ver onde aparece; ela troca no admin.
update public.store_settings
   set announcement = 'Entregas em Recife e região metropolitana. Pix, cartão ou dinheiro na entrega.'
 where id = 1 and announcement is null;
